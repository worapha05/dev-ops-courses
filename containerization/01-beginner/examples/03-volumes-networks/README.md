# 03 — Volumes & Networks

folder นี้มี `docker-compose.yml` เล็ก ๆ ที่สาธิต:

- **Named volume** เก็บไฟล์ที่เขียนจาก app
- **Bridge network** ให้ `writer` กับ `reader` คุยกันได้ด้วยชื่อ service

```bash
docker compose up --build
docker compose exec reader sh -c "ls -la /data && cat /data/hello.txt"
docker compose down -v
```
