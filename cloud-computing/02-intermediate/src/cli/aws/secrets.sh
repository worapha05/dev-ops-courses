#!/usr/bin/env bash
# สร้าง/หมุนเวียน secret บน AWS Secrets Manager โดยไม่ echo ค่าออกหน้าจอ
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/src/env/.env" 2> /dev/null || true

AWS_PROFILE="${AWS_PROFILE:-default}"
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
SECRET_NAME="${AWS_SECRET_NAME:-ccp-mid/db/credentials}"

ACTION="${1:-put}" # put | rotate-demo | get-meta

case "${ACTION}" in
  put)
    : "${DB_PASSWORD:?Set DB_PASSWORD in environment for one-shot put (not in git)}"
    aws secretsmanager create-secret \
      --name "${SECRET_NAME}" \
      --secret-string "{\"password\":\"${DB_PASSWORD}\"}" \
      --profile "${AWS_PROFILE}" --region "${AWS_REGION}" 2> /dev/null \
      || aws secretsmanager put-secret-value \
        --secret-id "${SECRET_NAME}" \
        --secret-string "{\"password\":\"${DB_PASSWORD}\"}" \
        --profile "${AWS_PROFILE}" --region "${AWS_REGION}"
    unset DB_PASSWORD
    echo "Secret stored/updated: ${SECRET_NAME}"
    ;;
  rotate-demo)
    NEW_PASS="$(openssl rand -base64 24 | tr -d '=+/' | cut -c1-24)"
    aws secretsmanager put-secret-value \
      --secret-id "${SECRET_NAME}" \
      --secret-string "{\"password\":\"${NEW_PASS}\"}" \
      --profile "${AWS_PROFILE}" --region "${AWS_REGION}"
    unset NEW_PASS
    echo "Rotated secret version for ${SECRET_NAME} (password not printed)"
    ;;
  get-meta)
    aws secretsmanager describe-secret \
      --secret-id "${SECRET_NAME}" \
      --profile "${AWS_PROFILE}" --region "${AWS_REGION}"
    ;;
  *)
    echo "usage: $0 put|rotate-demo|get-meta" >&2
    exit 1
    ;;
esac
