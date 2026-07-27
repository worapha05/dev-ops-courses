# Lab ระดับ Beginner — แพ็ค Full-stack ของทีม “CafeStack”

## เป้าหมาย

จำลองสถานการณ์ร้านกาแฟออนไลน์ **CafeStack** ที่ต้องย้ายจาก “รัน Node ตรงบนเครื่อง” ไปเป็น **Docker + Compose**:

- เขียน Dockerfile สำหรับ frontend และ backend
- ออกแบบ volume ให้ PostgreSQL ไม่หายเมื่อ recreate container
- สร้าง network ให้บริการคุยกันด้วยชื่อ service
- สตาร์ททั้งชุดด้วย `docker compose up --build` คำสั่งเดียว

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

ทีม CafeStack มี 3 ส่วน:

| ส่วน     | เทคโนโลยี           | ปัญหาปัจจุบัน                             |
| -------- | ------------------- | ----------------------------------------- |
| Frontend | nginx + static HTML | แต่ละคนติดตั้ง nginx คนละ version         |
| Backend  | Node.js Express     | “works on my machine” เพราะ Node 18 vs 20 |
| Database | PostgreSQL          | ลบ container แล้วเมนูเครื่องดื่มหาย       |

CTO กำหนด Definition of Done:

> “นักพัฒนาใหม่ clone แล้วรัน `docker compose up --build` ต้องเห็นเมนูบน browser ภายใน 5 นาที โดยไม่ติดตั้ง Node/Postgres บน host”

คุณอาจใช้โค้ดจาก [`./sample-app/`](./sample-app/) เป็นต้นแบบ หรือสร้างใหม่ใน folder lab ของคุณ

---

## โจทย์

### ส่วนที่ 1 — Dockerfile Backend

สร้าง `backend/Dockerfile` ที่:

1. ใช้ base `node:20-alpine`
2. ตั้ง `WORKDIR /app`
3. คัดลอก `package.json` แล้ว `npm install` ก่อนคัดลอก source (เพื่อ cache)
4. `EXPOSE 3000`
5. รันด้วย `USER node` และ `CMD` แบบ exec form

### ส่วนที่ 2 — Dockerfile Frontend

สร้าง `frontend/Dockerfile` ที่:

1. ใช้ `nginx:1.27-alpine` (หรือรุ่นใกล้เคียง)
2. คัดลอก static files ไป `/usr/share/nginx/html`
3. มี `nginx.conf` ที่ proxy `/api/` ไปยัง `http://backend:3000/api/`

### ส่วนที่ 3 — docker-compose.yml

สร้างไฟล์ที่ root ของ project lab:

```text
docker-compose.yml
```

ข้อกำหนด:

1. มี services: `frontend`, `backend`, `db`
2. `db` ใช้ `postgres:16-alpine` พร้อม **named volume** สำหรับ data
3. `backend` ได้ `DATABASE_URL` ชี้ไปที่ host ชื่อ `db`
4. `frontend` publish port `8080:80`
5. ทุก service อยู่ใน custom bridge network เดียวกัน
6. ใช้ `depends_on` (แนะนำใส่ healthcheck ของ `db` / `backend`)

### ส่วนที่ 4 — ทดสอบและดีบัก

1. `docker compose up --build`
2. เปิด `http://localhost:8080` แล้วเห็นรายการสินค้า/เมนู
3. `curl http://localhost:3000/health` ได้ JSON สถานะ OK
4. `docker compose down` แล้ว `up` ใหม่ — **ข้อมูล seed ยังอยู่** (หรืออย่างน้อย schema ไม่พัง) เพราะใช้ volume
5. จงใจทำให้ backend พัง (เช่นแก้ `DATABASE_URL` ผิด) แล้วใช้ `docker compose logs backend` หาสาเหตุ

### ส่วนที่ 5 — คำถามคิด (ตอบใน `NOTES.md`)

1. ทำไม frontend ถึงเรียก backend ด้วยชื่อ `backend` ได้ แต่จาก browser บน host ต้องใช้ `localhost:8080`?
2. ความต่างของ `docker compose down` กับ `docker compose down -v` คืออะไร — เมื่อไหร่ห้ามใช้ `-v`?
3. ถ้าจะแชร์ project นี้ให้เพื่อนโดยไม่ส่งรหัสผ่าน DB ไปใน Git ควรทำอย่างไร?

---

## เกณฑ์ผ่าน

- [ ] มี Dockerfile frontend + backend ที่ build ผ่าน
- [ ] `docker compose up --build` รันครบ 3 services
- [ ] UI หรือ API แสดงข้อมูลจาก Postgres ได้
- [ ] ใช้ named volume สำหรับ DB
- [ ] ตอบคำถามส่วนที่ 5 ได้
- [ ] ไม่มี secret production ถูก commit

---

## คำใบ้

- ทฤษฎี: [`README.md`](./README.md)
- Compose ตัวอย่าง: [`examples/04-docker-compose/`](./examples/04-docker-compose/)
- ชุดสมบูรณ์: [`./sample-app/`](./sample-app/)

---

## เฉลย

อยู่ที่ [`lab/solution/`](./lab/solution/) — เปิดเมื่อทำเองแล้วเท่านั้น
