#!/usr/bin/env bash
# Rotate DB secret แล้วบังคับ deploy ใหม่ (AWS ECS หรือ GCP Cloud Run)
set -euo pipefail

CLOUD="${1:?usage: $0 aws|gcp ...}"

if [[ "${CLOUD}" == "aws" ]]; then
  SECRET_ID="${2:?}"
  CLUSTER="${3:?}"
  SERVICE="${4:?}"
  AWS_PROFILE="${AWS_PROFILE:-default}"
  AWS_REGION="${AWS_REGION:-ap-southeast-1}"

  NEW_PASS="$(openssl rand -base64 24 | tr -d '=+/' | cut -c1-24)"
  # ดึง metadata เดิมโดยไม่พิมพ์ password — ใน production ใช้ rotation Lambda + ALTER ROLE
  aws secretsmanager put-secret-value \
    --secret-id "${SECRET_ID}" \
    --secret-string "{\"password\":\"${NEW_PASS}\",\"rotated_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
    --profile "${AWS_PROFILE}" --region "${AWS_REGION}"
  unset NEW_PASS

  aws ecs update-service --cluster "${CLUSTER}" --service "${SERVICE}" \
    --force-new-deployment --profile "${AWS_PROFILE}" --region "${AWS_REGION}" > /dev/null
  echo "AWS: secret rotated + ECS force-new-deployment triggered"
elif [[ "${CLOUD}" == "gcp" ]]; then
  SECRET_ID="${2:?}"
  SERVICE="${3:?}"
  REGION="${4:-asia-southeast1}"
  NEW_PASS="$(openssl rand -base64 24 | tr -d '=+/' | cut -c1-24)"
  printf '%s' "{\"password\":\"${NEW_PASS}\"}" | gcloud secrets versions add "${SECRET_ID}" --data-file=-
  unset NEW_PASS
  gcloud run services update "${SERVICE}" --region="${REGION}" --update-env-vars="SECRET_BUMP=$(date +%s)" > /dev/null
  echo "GCP: new secret version + Cloud Run revision bump"
else
  echo "usage: $0 aws <secret> <cluster> <service> | $0 gcp <secret> <service> [region]" >&2
  exit 1
fi
