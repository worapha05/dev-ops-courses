# 01 — Multi-stage Dockerfile

ตัวอย่าง Node API ที่แยก build / runtime สำหรับ platform แบบ Cloud Run

```bash
docker build -t multistage-demo:1.0.0 .
docker run --rm -p 8080:8080 -e PORT=8080 multistage-demo:1.0.0
curl http://localhost:8080/health
```

เปรียบเทียบขนาด:

```bash
docker images multistage-demo
```
