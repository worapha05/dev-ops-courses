#!/usr/bin/env bash
set -euo pipefail

NAME="bootcamp-cli-demo"

cleanup() {
  docker rm -f "$NAME" > /dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Pull image"
docker pull nginx:1.27-alpine

echo "==> Run container on host port 18080"
docker run -d --name "$NAME" -p 18080:80 nginx:1.27-alpine

echo "==> docker ps"
docker ps --filter "name=$NAME"

echo "==> logs (last 5 lines)"
docker logs --tail 5 "$NAME"

echo "==> exec: list html root"
docker exec "$NAME" ls /usr/share/nginx/html

echo "==> HTTP check"
curl -fsS "http://127.0.0.1:18080/" | head -n 5

echo "==> Done (container will be removed on exit)"
