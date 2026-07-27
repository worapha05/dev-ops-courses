#!/usr/bin/env bash
# สร้าง log-based metric + alerting นโยบายพื้นฐานบน GCP
set -euo pipefail

GCP_PROJECT_ID="${GCP_PROJECT_ID:?}"
PREFIX="${1:-ccp-xprt}"
CHANNEL="${NOTIFICATION_CHANNEL:-}"

gcloud config set project "${GCP_PROJECT_ID}" > /dev/null

# เปิดใช้งาน alpha component สำหรับ gcloud alpha monitoring policies
if ! gcloud components list --format="value(id)" 2> /dev/null | grep -q "^alpha$"; then
  echo "==> Installing gcloud alpha component..."
  gcloud components install alpha --quiet
fi

gcloud logging metrics create "${PREFIX}_error_count" \
  --description="Count of severity>=ERROR" \
  --log-filter='severity>=ERROR' 2> /dev/null \
  || gcloud logging metrics update "${PREFIX}_error_count" \
    --log-filter='severity>=ERROR'

if [[ -n "${CHANNEL}" ]]; then
  gcloud alpha monitoring policies create \
    --notification-channels="${CHANNEL}" \
    --display-name="${PREFIX} error rate" \
    --condition-display-name="error count" \
    --condition-filter='metric.type="logging.googleapis.com/user/'"${PREFIX}"'_error_count"' \
    --condition-threshold-value=5 \
    --condition-threshold-comparison=COMPARISON_GT \
    --duration=60s 2> /dev/null \
    || echo "Create policy via console if alpha command unavailable"
fi

echo "Baseline logging metric ready: ${PREFIX}_error_count"
