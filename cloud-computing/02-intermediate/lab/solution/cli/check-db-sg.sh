#!/usr/bin/env bash
# ตรวจว่า DB SG รับได้เฉพาะจาก app SG (AWS)
set -euo pipefail

DB_SG="${1:?usage: $0 <db-sg-id>}"
AWS_PROFILE="${AWS_PROFILE:-default}"
AWS_REGION="${AWS_REGION:-ap-southeast-1}"

aws ec2 describe-security-groups --group-ids "${DB_SG}" \
  --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
  --query 'SecurityGroups[0].IpPermissions' --output json

echo "Expect: tcp/5432 from App SG only — no 0.0.0.0/0"
