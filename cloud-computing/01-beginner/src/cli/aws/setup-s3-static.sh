#!/usr/bin/env bash
# สร้าง S3 bucket สำหรับ static assets พร้อม Block Public Access + versioning + lifecycle
# Usage: ./setup-s3-static.sh [bucket-name]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/src/env/.env" 2> /dev/null || true

AWS_REGION="${AWS_REGION:-ap-southeast-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"
BUCKET="${1:-${PROJECT_NAME:-ccp-bootcamp}-static-${BUCKET_SUFFIX:-demo}}"

echo "==> Creating bucket s3://${BUCKET} in ${AWS_REGION} (profile=${AWS_PROFILE})"

if [[ "${AWS_REGION}" == "us-east-1" ]]; then
  aws s3api create-bucket \
    --bucket "${BUCKET}" \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}"
else
  aws s3api create-bucket \
    --bucket "${BUCKET}" \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}"
fi

aws s3api put-public-access-block \
  --bucket "${BUCKET}" \
  --profile "${AWS_PROFILE}" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --profile "${AWS_PROFILE}" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "${BUCKET}" \
  --profile "${AWS_PROFILE}" \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

aws s3api put-bucket-lifecycle-configuration \
  --bucket "${BUCKET}" \
  --profile "${AWS_PROFILE}" \
  --lifecycle-configuration '{
    "Rules": [{
      "ID": "transition-and-expire-old-versions",
      "Status": "Enabled",
      "Filter": {"Prefix": ""},
      "Transitions": [{"Days": 30, "StorageClass": "STANDARD_IA"}],
      "NoncurrentVersionExpiration": {"NoncurrentDays": 90}
    }]
  }'

aws s3api put-bucket-tagging \
  --bucket "${BUCKET}" \
  --profile "${AWS_PROFILE}" \
  --tagging "TagSet=[{Key=env,Value=${ENVIRONMENT:-dev}},{Key=project,Value=${PROJECT_NAME:-ccp-bootcamp}}]"

echo "==> Done. Bucket is private by default. Put CloudFront/OAC in front for public web hosting."
echo "    aws s3 ls s3://${BUCKET} --profile ${AWS_PROFILE}"
