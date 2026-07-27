# 03 — Caching & Runner Optimization

| ไฟล์                                                 | เนื้อหา                                     |
| ---------------------------------------------------- | ------------------------------------------- |
| [`cache-npm.yml`](./cache-npm.yml)                   | setup-node cache + concurrency              |
| [`cache-multi-lang.yml`](./cache-multi-lang.yml)     | ตัวอย่าง npm / pip / go กับ `actions/cache` |
| [`docker-layer-cache.yml`](./docker-layer-cache.yml) | Buildx cache แบบ GHA                        |

## หลักจำ

- Cache key ต้องรวม **lockfile hash**
- `restore-keys` เป็น fallback เมื่อ key ไม่ตรงเป๊ะ
- Docker layer cache ช่วยมากเมื่อ Dockerfile เรียงจากของเปลี่ยนน้อย → เปลี่ยนบ่อย
