#!/usr/bin/env bash
# สร้าง IAM Group + managed policy แบบ Least Privilege สำหรับทีม Dev ที่อ่าน S3 ได้เฉพาะ prefix
# Usage: ./iam-bootstrap.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/src/env/.env" 2> /dev/null || true

AWS_PROFILE="${AWS_PROFILE:-default}"
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
GROUP_NAME="${PROJECT_NAME:-ccp-bootcamp}-devs"
POLICY_NAME="${PROJECT_NAME:-ccp-bootcamp}-s3-read-prefix"
BUCKET="${PROJECT_NAME:-ccp-bootcamp}-static-${BUCKET_SUFFIX:-demo}"

echo "==> Ensuring IAM group: ${GROUP_NAME}"
aws iam create-group --group-name "${GROUP_NAME}" --profile "${AWS_PROFILE}" 2> /dev/null || true

POLICY_DOC=$(
  cat << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListOnlyThisBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${BUCKET}"],
      "Condition": {
        "StringLike": {"s3:prefix": ["public/*", ""]}
      }
    },
    {
      "Sid": "ReadPublicPrefixOnly",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::${BUCKET}/public/*"]
    }
  ]
}
EOF
)

TMP_POLICY="$(mktemp)"
echo "${POLICY_DOC}" > "${TMP_POLICY}"

ACCOUNT_ID="$(aws sts get-caller-identity --profile "${AWS_PROFILE}" --query Account --output text)"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn "${POLICY_ARN}" --profile "${AWS_PROFILE}" > /dev/null 2>&1; then
  echo "==> Policy exists, creating new version"
  aws iam create-policy-version \
    --policy-arn "${POLICY_ARN}" \
    --policy-document "file://${TMP_POLICY}" \
    --set-as-default \
    --profile "${AWS_PROFILE}"
else
  echo "==> Creating policy ${POLICY_NAME}"
  aws iam create-policy \
    --policy-name "${POLICY_NAME}" \
    --policy-document "file://${TMP_POLICY}" \
    --profile "${AWS_PROFILE}"
fi

aws iam attach-group-policy \
  --group-name "${GROUP_NAME}" \
  --policy-arn "${POLICY_ARN}" \
  --profile "${AWS_PROFILE}"

rm -f "${TMP_POLICY}"
echo "==> Attach users to group with: aws iam add-user-to-group --group-name ${GROUP_NAME} --user-name USER"
echo "==> Region context: ${AWS_REGION}"
