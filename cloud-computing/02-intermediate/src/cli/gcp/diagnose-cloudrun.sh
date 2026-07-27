#!/usr/bin/env bash
# ตรวจ Cloud Run + VPC + Secret access
set -euo pipefail

GCP_PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID}"
SERVICE="${1:?usage: $0 <cloud-run-service> [region]}"
REGION="${2:-asia-southeast1}"

gcloud config set project "${GCP_PROJECT_ID}" > /dev/null

echo "==> Service status"
gcloud run services describe "${SERVICE}" --region="${REGION}" \
  --format='yaml(status.conditions,status.url,spec.template.serviceAccountName)'

echo "==> Recent revisions"
gcloud run revisions list --service="${SERVICE}" --region="${REGION}" --limit=5

echo "==> Tip: Secret access denied => grant secretAccessor to runtime SA"
echo "==> Tip: Cloud SQL connection refused => private IP + cloudsql.client + VPC egress"
