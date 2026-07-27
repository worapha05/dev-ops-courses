# Sample App — ShopLite

แอป Full-stack จำลองร้านค้าเล็ก ๆ ใช้เป็นฐานใน Lab ทั้ง 3 ระดับ

```
sample-app/
├── docker-compose.yml # Beginner: รันทั้งชุดในเครื่อง
├── frontend/  # nginx + static HTML
├── backend/  # Node.js Express API
└── README.md
```

## บริการ

| Service    | Image / Build         | Port                     | หน้าที่                           |
| ---------- | --------------------- | ------------------------ | --------------------------------- |
| `frontend` | build จาก `frontend/` | 8080→80                  | UI เรียก `/api`                   |
| `backend`  | build จาก `backend/`  | 3000                     | REST API                          |
| `db`       | `postgres:16-alpine`  | (ภายใน network เท่านั้น) | เก็บสินค้า — ไม่ publish ออก host |

## รันเร็ว

```bash
cd sample-app
docker compose up --build

# เปิด browser
# http://localhost:8080

# ทดสอบ API โดยตรง
curl http://localhost:3000/health
curl http://localhost:3000/api/products
```

## Environment

คัดลอกจาก `.env.example` ถ้าต้องการปรับค่า:

```bash
cp .env.example .env
```

> **อย่า commit** ไฟล์ `.env` ที่มีรหัสผ่านจริง
