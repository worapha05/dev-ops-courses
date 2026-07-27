#!/usr/bin/env bash
set -euo pipefail

# วางใน Jenkins Freestyle → Build → Execute shell
# ปรับเส้นทางให้ตรงกับ workspace ของคุณ

echo "event context: BUILD_NUMBER=${BUILD_NUMBER:-local} JOB_NAME=${JOB_NAME:-local}"

APP_DIR="${WORKSPACE}/01-beginner/sample-app"
if [[ ! -d "$APP_DIR" ]]; then
  # fallback เมื่อ checkout เฉพาะ sample-app
  APP_DIR="${WORKSPACE}"
fi

cd "$APP_DIR"
node -v
npm install
npm run lint
npm test
echo "NovaPay Freestyle CI OK"
