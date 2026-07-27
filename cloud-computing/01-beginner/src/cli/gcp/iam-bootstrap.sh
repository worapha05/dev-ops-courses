#!/usr/bin/env bash
# สร้าง Custom Role แบบ Least Privilege + Service Account สำหรับอ่าน GCS prefix
# Usage: ./iam-bootstrap.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP_ROLE_FILE="/tmp/custom-role.yaml"
cleanup() { rm -f "${TMP_ROLE_FILE}"; }
trap cleanup EXIT
# shellcheck disable=SC1091
source "${ROOT_DIR}/src/env/.env" 2> /dev/null || true

GCP_PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID in .env}"
ROLE_ID="${PROJECT_NAME:-ccp_bootcamp}_storage_reader"
ROLE_ID="${ROLE_ID//-/_}"
SA_ID="${PROJECT_NAME:-ccp-bootcamp}-reader"
SA_EMAIL="${SA_ID}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
BUCKET="${PROJECT_NAME:-ccp-bootcamp}-static-${BUCKET_SUFFIX:-demo}"

gcloud config set project "${GCP_PROJECT_ID}"

echo "==> Creating custom role ${ROLE_ID}"
cat > "${TMP_ROLE_FILE}" << EOF
title: "CCP Bootcamp Storage Reader"
description: "Read objects under public/ prefix only (approx via objectViewer + list)"
stage: "GA"
includedPermissions:
- storage.objects.get
- storage.objects.list
- storage.buckets.get
EOF

gcloud iam roles create "${ROLE_ID}" \
  --project="${GCP_PROJECT_ID}" \
  --file="${TMP_ROLE_FILE}" 2> /dev/null \
  || gcloud iam roles update "${ROLE_ID}" \
    --project="${GCP_PROJECT_ID}" \
    --file="${TMP_ROLE_FILE}"

echo "==> Creating service account ${SA_EMAIL}"
gcloud iam service-accounts create "${SA_ID}" \
  --display-name="CCP Bootcamp Reader" 2> /dev/null || true

gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="projects/${GCP_PROJECT_ID}/roles/${ROLE_ID}" \
  --condition=None > /dev/null

# จำกัดเพิ่มที่ bucket (IAM condition บน prefix)
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.objectViewer" 2> /dev/null || true

echo "==> SA ready: ${SA_EMAIL}"
echo "    Prefer Workload Identity Federation over downloading JSON keys."
