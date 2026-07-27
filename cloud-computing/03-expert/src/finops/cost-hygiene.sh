#!/usr/bin/env bash
# FinOps checklist automation stubs — right-size hints + budget
set -euo pipefail

CLOUD="${1:-aws}"

if [[ "${CLOUD}" == "aws" ]]; then
  AWS_PROFILE="${AWS_PROFILE:-default}"
  AWS_REGION="${AWS_REGION:-ap-southeast-1}"

  echo "==> Unattached EIPs (often forgotten cost)"
  aws ec2 describe-addresses \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --query 'Addresses[?AssociationId==`null`].PublicIp' \
    --output table

  echo "==> NAT Gateways"
  aws ec2 describe-nat-gateways \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --filter Name=state,Values=available \
    --query 'NatGateways[].{id:NatGatewayId,subnet:SubnetId}' \
    --output table

  echo "==> Tip: enable Cost Explorer + Budgets anomaly detection in console/API"

elif [[ "${CLOUD}" == "gcp" ]]; then
  GCP_PROJECT_ID="${GCP_PROJECT_ID:?}"

  echo "==> Idle addresses"
  gcloud compute addresses list \
    --project="${GCP_PROJECT_ID}" \
    --filter="status=RESERVED" || true

  echo "==> Tip: recommender API for idle VM / CUDs; set budget in Cloud Billing"

else
  echo "usage: $0 aws|gcp" >&2
  exit 1
fi
