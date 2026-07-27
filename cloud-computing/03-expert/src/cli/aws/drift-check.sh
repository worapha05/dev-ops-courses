#!/usr/bin/env bash
# ตรวจ terraform drift แบบ non-interactive สำหรับ CI
set -euo pipefail

DIR="${1:?usage: $0 <terraform-dir>}"

cd "${DIR}"
terraform init -input=false

set +e
terraform plan -detailed-exitcode -input=false -no-color
CODE=$?
set -e

case "${CODE}" in
  0)
    echo "No changes (no drift detected in plan)"
    ;;
  2)
    echo "DRIFT_OR_CHANGES detected"
    exit 2
    ;;
  *)
    echo "Plan failed"
    exit 1
    ;;
esac
