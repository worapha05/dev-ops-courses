#!/usr/bin/env bash
# Launch EC2 หลัง ALB แบบย่อ (สำหรับเรียนรู้) — production ควรใช้ Terraform/ASG
# Usage: ./launch-ec2-asg-demo.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/src/env/.env" 2> /dev/null || true

AWS_PROFILE="${AWS_PROFILE:-default}"
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
NAME_PREFIX="${PROJECT_NAME:-ccp-bootcamp}"

echo "==> Resolving default VPC and subnets in ${AWS_REGION}"
VPC_ID="$(aws ec2 describe-vpcs --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
  --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)"
SUBNETS="$(aws ec2 describe-subnets --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
  --filters "Name=vpc-id,Values=${VPC_ID}" --query 'Subnets[*].SubnetId' --output text)"
SUBNET_ARR=(${SUBNETS})
if [[ ${#SUBNET_ARR[@]} -lt 2 ]]; then
  echo "Need at least 2 subnets in default VPC for multi-AZ demo" >&2
  exit 1
fi

AMI_ID="$(aws ssm get-parameters \
  --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
  --query 'Parameters[0].Value' --output text)"

SG_ID="$(aws ec2 create-security-group \
  --group-name "${NAME_PREFIX}-web-sg" \
  --description "Bootcamp web SG" \
  --vpc-id "${VPC_ID}" \
  --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
  --query GroupId --output text 2> /dev/null \
  || aws ec2 describe-security-groups --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
    --filters Name=group-name,Values="${NAME_PREFIX}-web-sg" Name=vpc-id,Values="${VPC_ID}" \
    --query 'SecurityGroups[0].GroupId' --output text)"

aws ec2 authorize-security-group-ingress \
  --group-id "${SG_ID}" --protocol tcp --port 80 --cidr 0.0.0.0/0 \
  --profile "${AWS_PROFILE}" --region "${AWS_REGION}" 2> /dev/null || true

LT_ID="$(aws ec2 create-launch-template \
  --launch-template-name "${NAME_PREFIX}-lt" \
  --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
  --launch-template-data "{
    \"ImageId\": \"${AMI_ID}\",
    \"InstanceType\": \"t3.micro\",
    \"SecurityGroupIds\": [\"${SG_ID}\"],
    \"UserData\": \"$(echo '#!/bin/bash
yum install -y nginx
systemctl enable --now nginx
echo OK > /usr/share/nginx/html/healthz
' | base64 -w0)\"
  }" \
  --query 'LaunchTemplate.LaunchTemplateId' --output text 2> /dev/null \
  || aws ec2 describe-launch-templates --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
    --launch-template-names "${NAME_PREFIX}-lt" \
    --query 'LaunchTemplates[0].LaunchTemplateId' --output text)"

echo "==> Creating Auto Scaling Group across ${SUBNET_ARR[0]}, ${SUBNET_ARR[1]}"
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name "${NAME_PREFIX}-asg" \
  --launch-template "LaunchTemplateId=${LT_ID},Version=\$Latest" \
  --min-size 1 --max-size 3 --desired-capacity 2 \
  --vpc-zone-identifier "${SUBNET_ARR[0]},${SUBNET_ARR[1]}" \
  --health-check-type EC2 \
  --tags "ResourceId=${NAME_PREFIX}-asg,ResourceType=auto-scaling-group,Key=Name,Value=${NAME_PREFIX}-asg,PropagateAtLaunch=true" \
  --profile "${AWS_PROFILE}" --region "${AWS_REGION}" 2> /dev/null \
  || echo "ASG may already exist — check console/CLI"

echo "==> Demo ASG ready. Prefer Terraform for repeatable labs. Cleanup:"
echo "    aws autoscaling delete-auto-scaling-group --auto-scaling-group-name ${NAME_PREFIX}-asg --force-delete --profile ${AWS_PROFILE} --region ${AWS_REGION}"
