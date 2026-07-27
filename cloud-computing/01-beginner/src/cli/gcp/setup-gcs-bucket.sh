#!/usr/bin/env bash
# สร้าง GCS bucket + lifecycle + uniform access (ปิด ACLs แบบ object-level)
# Usage: ./setup-gcs-bucket.sh [bucket-name]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP_LIFECYCLE_FILE="/tmp/gcs-lifecycle.json"
cleanup() { rm -f "${TMP_LIFECYCLE_FILE}"; }
trap cleanup EXIT
# shellcheck disable=SC1091
source "${ROOT_DIR}/src/env/.env" 2> /dev/null || true

GCP_PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID in .env}"
GCP_REGION="${GCP_REGION:-asia-southeast1}"
BUCKET="${1:-${PROJECT_NAME:-ccp-bootcamp}-static-${BUCKET_SUFFIX:-demo}}"

gcloud config set project "${GCP_PROJECT_ID}"

echo "==> Creating gs://${BUCKET} in ${GCP_REGION}"
gcloud storage buckets create "gs://${BUCKET}" \
  --project="${GCP_PROJECT_ID}" \
  --location="${GCP_REGION}" \
  --uniform-bucket-level-access \
  --public-access-prevention 2> /dev/null || echo "Bucket may already exist"

gcloud storage buckets update "gs://${BUCKET}" --versioning

# Lifecycle: Nearline @30d, delete noncurrent @90d
cat > "${TMP_LIFECYCLE_FILE}" << 'EOF'
{
  "rule": [
    {
      "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
      "condition": {"age": 30, "matchesStorageClass": ["STANDARD"]}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"daysSinceNoncurrentTime": 90, "isLive": false}
    }
  ]
}
EOF

gcloud storage buckets update "gs://${BUCKET}" --lifecycle-file="${TMP_LIFECYCLE_FILE}"

gcloud storage buckets update "gs://${BUCKET}" \
  --update-labels=env="${ENVIRONMENT:-dev}",project="${PROJECT_NAME:-ccp-bootcamp}"

echo "==> Done. Bucket uses public access prevention. Serve via Cloud CDN / LB backend bucket."
echo "    gcloud storage ls gs://${BUCKET}"
