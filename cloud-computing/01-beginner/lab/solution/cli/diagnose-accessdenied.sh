#!/usr/bin/env bash
# วินิจฉัย AccessDenied / สิทธิ์ไม่พอ สำหรับ ShopLite
set -euo pipefail

CLOUD="${1:-aws}" # aws | gcp
TARGET="${2:-}"

if [[ "${CLOUD}" == "aws" ]]; then
  : "${TARGET:?usage: $0 aws <bucket>}"
  echo "==> Caller"
  aws sts get-caller-identity
  echo "==> Probe list/get (expect fail if PoLP correct for humans without CI role)"
  aws s3api list-objects-v2 --bucket "${TARGET}" --prefix public/ --max-keys 1 || true
  aws s3api get-object --bucket "${TARGET}" --key public/probe.txt /tmp/probe.txt || true
  echo "==> Tip: upload needs PutObject on a dedicated CI role, not broad AdminAccess"
elif [[ "${CLOUD}" == "gcp" ]]; then
  : "${TARGET:?usage: $0 gcp gs://bucket}"
  echo "==> Active account"
  gcloud auth list --filter=status:ACTIVE --format='value(account)'
  gcloud storage ls "${TARGET}/public/" || true
  echo "==> Tip: grant storage.objectCreator on prefix via conditional IAM for CI SA only"
else
  echo "usage: $0 aws <bucket> | $0 gcp gs://bucket" >&2
  exit 1
fi
