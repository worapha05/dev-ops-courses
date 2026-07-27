#!/usr/bin/env bash
# ตรวจ networking: SG rules, subnet routes, ECS tasks ไม่ขึ้น
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-default}"
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
CLUSTER="${1:?usage: $0 <ecs-cluster> <service>}"
SERVICE="${2:?usage: $0 <ecs-cluster> <service>}"

echo "==> ECS service events (last failures often show SG/subnet/secret issues)"
aws ecs describe-services \
  --cluster "${CLUSTER}" --services "${SERVICE}" \
  --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
  --query 'services[0].events[0:5]' --output table

echo "==> Running tasks"
TASKS="$(aws ecs list-tasks --cluster "${CLUSTER}" --service-name "${SERVICE}" \
  --profile "${AWS_PROFILE}" --region "${AWS_REGION}" --query 'taskArns' --output text)"
if [[ -n "${TASKS}" && "${TASKS}" != "None" ]]; then
  aws ecs describe-tasks --cluster "${CLUSTER}" --tasks "${TASKS}" \
    --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
    --query 'tasks[].{lastStatus:lastStatus,stoppedReason:stoppedReason,connectivity:connectivity}' \
    --output table
fi

echo "==> Tip: AccessDenied on secrets => check execution role GetSecretValue"
echo "==> Tip: ResourceInitializationError => image pull / NAT / ECR endpoint"
