#!/usr/bin/env bash
# สำเนา object สำคัญไปยัง GCS DR bucket (ตัวอย่าง multi-cloud)
set -euo pipefail

SRC="${1:?usage: $0 s3://bucket/prefix gs://dr-bucket/prefix}"
DST="${2:?}"

echo "Sync ${SRC} -> ${DST}"
# ใช้ aws s3 sync ลง local แล้ว gcloud storage rsync — หรือ transfer service ใน production
TMP="$(mktemp -d)"

aws s3 sync "${SRC}" "${TMP}/"
gcloud storage rsync "${TMP}/" "${DST}" --recursive
rm -rf "${TMP}"

echo "Done"
