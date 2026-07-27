#!/usr/bin/env bash
# ปิด public access ฉุกเฉินหลังมีคนเปิด bucket โล่ง
set -euo pipefail

CLOUD="${1:-}"
TARGET="${2:-}"

if [[ "${CLOUD}" == "aws" ]]; then
  : "${TARGET:?usage: $0 aws <bucket>}"
  aws s3api put-public-access-block --bucket "${TARGET}" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  aws s3api delete-bucket-policy --bucket "${TARGET}" 2> /dev/null || true
  echo "AWS bucket locked down: ${TARGET}"
elif [[ "${CLOUD}" == "gcp" ]]; then
  : "${TARGET:?usage: $0 gcp gs://bucket}"
  gcloud storage buckets update "${TARGET}" \
    --uniform-bucket-level-access \
    --public-access-prevention
  # ลบ allUsers / allAuthenticatedUsers ถ้ามี
  gcloud storage buckets remove-iam-policy-binding "${TARGET}" \
    --member=allUsers --role=roles/storage.objectViewer 2> /dev/null || true
  gcloud storage buckets remove-iam-policy-binding "${TARGET}" \
    --member=allAuthenticatedUsers --role=roles/storage.objectViewer 2> /dev/null || true
  echo "GCS bucket locked down: ${TARGET}"
else
  echo "usage: $0 aws <bucket> | $0 gcp gs://bucket" >&2
  exit 1
fi
