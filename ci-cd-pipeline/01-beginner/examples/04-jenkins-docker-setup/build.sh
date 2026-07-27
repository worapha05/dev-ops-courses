#!/usr/bin/env bash
# สคริปต์ที่วางใน Freestyle "Execute shell" ได้
set -euo pipefail

echo "==> CI Beginner build script"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# เมื่อรันจาก Jenkins workspace ให้ชี้ไปที่ sample-app ใน repo
APP_DIR="${WORKSPACE:-$ROOT}/01-beginner/sample-app"

if [[ ! -d "$APP_DIR" ]]; then
  echo "ไม่พบ sample-app ที่ $APP_DIR" >&2
  exit 1
fi

cd "$APP_DIR"
node -v
npm install
npm run lint
npm test
echo "==> OK"
