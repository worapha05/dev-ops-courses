#!/usr/bin/env bash
# จำลองการตรวจ health ของ primary แล้วรายงานว่าควร failover หรือไม่
set -euo pipefail

URL="${1:?usage: $0 https://primary-alb.example/healthz}"
FAILS=0

for i in 1 2 3; do
  if curl -fsS --max-time 5 "${URL}" > /dev/null; then
    echo "ok attempt ${i}"
  else
    echo "fail attempt ${i}"
    FAILS=$((FAILS + 1))
  fi
  sleep 2
done

if [[ "${FAILS}" -ge 3 ]]; then
  echo "RECOMMEND_FAILOVER: primary unhealthy — Route 53 should shift to SECONDARY"
  exit 2
fi

echo "Primary healthy"
