# 04 — Docker Compose (API + Redis)

ตัวอย่างมินิมอล: API Node นับจำนวนครั้งด้วย Redis

```bash
docker compose up --build
curl http://localhost:3001/count
docker compose down -v
```

เปรียบเทียบกับชุด Full-stack จริงใน [`../../sample-app/`](../../sample-app/)
