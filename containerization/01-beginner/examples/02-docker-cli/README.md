# 02 — Docker CLI Basics

รัน script ทีละขั้นหรือคัดลอกคำสั่งไปฝึกเอง

```bash
chmod +x demo.sh
./demo.sh
```

## สิ่งที่ script สาธิต

1. `docker pull` / `docker images`
2. `docker run -d -p` สร้าง web server
3. `docker ps` / `docker logs` / `docker exec`
4. `docker stop` / `docker rm`

> ใช้ image `nginx:1.27-alpine` — ต้องมีเครือข่ายเพื่อ pull ครั้งแรก
