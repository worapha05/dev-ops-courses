#!/usr/bin/env bash
# สร้าง CloudWatch log group + metric alarm ตัวอย่าง (AWS)
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-default}"
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
PREFIX="${1:-ccp-xprt}"
SNS_TOPIC_ARN="${SNS_TOPIC_ARN:-}"

aws logs create-log-group \
  --log-group-name "/ccp/${PREFIX}/api" \
  --profile "${AWS_PROFILE}" \
  --region "${AWS_REGION}" 2> /dev/null || true

aws logs put-retention-policy \
  --log-group-name "/ccp/${PREFIX}/api" \
  --retention-in-days 30 \
  --profile "${AWS_PROFILE}" \
  --region "${AWS_REGION}"

if [[ -n "${SNS_TOPIC_ARN}" ]]; then
  aws cloudwatch put-metric-alarm \
    --alarm-name "${PREFIX}-alb-5xx" \
    --alarm-description "ALB 5xx spike" \
    --namespace AWS/ApplicationELB \
    --metric-name HTTPCode_Target_5XX_Count \
    --statistic Sum \
    --period 60 \
    --evaluation-periods 3 \
    --threshold 5 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --alarm-actions "${SNS_TOPIC_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}"
  echo "Alarm created and wired to SNS"
else
  echo "Set SNS_TOPIC_ARN to attach alarm actions"
fi
