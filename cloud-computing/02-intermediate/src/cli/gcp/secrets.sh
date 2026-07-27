#!/usr/bin/env bash
# สร้าง/หมุนเวียน secret บน GCP Secret Manager
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/src/env/.env" 2> /dev/null || true

GCP_PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID}"
SECRET_ID="${GCP_SECRET_ID:-ccp-mid-db-credentials}"
ACTION="${1:-put}"

gcloud config set project "${GCP_PROJECT_ID}" > /dev/null

case "${ACTION}" in
  put)
    : "${DB_PASSWORD:?Set DB_PASSWORD in environment for one-shot put}"
    printf '%s' "{\"password\":\"${DB_PASSWORD}\"}" \
      | gcloud secrets create "${SECRET_ID}" --data-file=- 2> /dev/null \
      || printf '%s' "{\"password\":\"${DB_PASSWORD}\"}" \
        | gcloud secrets versions add "${SECRET_ID}" --data-file=-
    unset DB_PASSWORD
    echo "Secret stored: ${SECRET_ID}"
    ;;
  rotate-demo)
    NEW_PASS="$(openssl rand -base64 24 | tr -d '=+/' | cut -c1-24)"
    printf '%s' "{\"password\":\"${NEW_PASS}\"}" \
      | gcloud secrets versions add "${SECRET_ID}" --data-file=-
    unset NEW_PASS
    echo "Added new secret version for ${SECRET_ID}"
    ;;
  get-meta)
    gcloud secrets describe "${SECRET_ID}"
    gcloud secrets versions list "${SECRET_ID}"
    ;;
  *)
    echo "usage: $0 put|rotate-demo|get-meta" >&2
    exit 1
    ;;
esac
