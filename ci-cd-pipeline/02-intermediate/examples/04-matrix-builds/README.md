# 04 — Matrix Builds

[`matrix-ci.yml`](./matrix-ci.yml) รัน test บน Node 18/20/22 และตัดบางคู่ด้วย `exclude`

สังเกต:

- `fail-fast: false` เพื่อให้เห็นผลทุกช่องแม้ช่องหนึ่ง fail
- `name:` ใส่ matrix values ให้อ่านง่ายใน UI
