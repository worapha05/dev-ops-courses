#!/usr/bin/env bash
# สรุปคำสั่งตรวจ drift + cost hygiene สำหรับรายงาน lab
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

echo "=== Drift check (example dir) ==="
bash "${ROOT}/src/cli/aws/drift-check.sh" "${ROOT}/src/terraform/aws" || true

echo "=== Cost hygiene ==="
bash "${ROOT}/src/finops/cost-hygiene.sh" aws || true

echo "=== Done — attach outputs to lab report ==="
