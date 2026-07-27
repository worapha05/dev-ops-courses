#!/usr/bin/env bash
# สร้าง Compute Engine VM + basic firewall (HTTP) สำหรับ demo
# Usage: ./launch-gce-mig-demo.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/src/env/.env" 2> /dev/null || true

GCP_PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID in .env}"
GCP_ZONE="${GCP_ZONE:-asia-southeast1-a}"
GCP_REGION="${GCP_REGION:-asia-southeast1}"
NAME_PREFIX="${PROJECT_NAME:-ccp-bootcamp}"

gcloud config set project "${GCP_PROJECT_ID}"

echo "==> Ensuring firewall allow-http tagged instances"
gcloud compute firewall-rules create "${NAME_PREFIX}-allow-http" \
  --allow=tcp:80 \
  --target-tags=http-server \
  --direction=INGRESS \
  --source-ranges=0.0.0.0/0 \
  --description="Bootcamp HTTP" 2> /dev/null || true

STARTUP=$(
  cat << 'EOF'
#!/bin/bash
apt-get update -y
apt-get install -y nginx
echo OK > /var/www/html/healthz
systemctl enable --now nginx
EOF
)

echo "==> Creating instance template"
gcloud compute instance-templates create "${NAME_PREFIX}-tpl" \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --tags=http-server \
  --metadata=startup-script="${STARTUP}" \
  --region="${GCP_REGION}" 2> /dev/null || echo "Template may exist"

echo "==> Creating Managed Instance Group"
gcloud compute instance-groups managed create "${NAME_PREFIX}-mig" \
  --template="${NAME_PREFIX}-tpl" \
  --size=2 \
  --zone="${GCP_ZONE}" 2> /dev/null || echo "MIG may exist"

gcloud compute instance-groups managed set-autoscaling "${NAME_PREFIX}-mig" \
  --zone="${GCP_ZONE}" \
  --min-num-replicas=1 \
  --max-num-replicas=3 \
  --target-cpu-utilization=0.6 \
  --cool-down-period=60 2> /dev/null || true

echo "==> MIG demo ready in ${GCP_ZONE}. Cleanup:"
echo "    gcloud compute instance-groups managed delete ${NAME_PREFIX}-mig --zone=${GCP_ZONE} --quiet"
echo "    gcloud compute instance-templates delete ${NAME_PREFIX}-tpl --quiet"
