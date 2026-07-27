# NOTES — คำตอบส่วนที่ 5

1. **ทำไมเรียกชื่อ `backend` ได้จาก nginx ใน container**
   Docker bridge network มี DNS ในbuilt-in ให้ service ใน compose resolve ชื่อ `backend` เป็น IP ของ container นั้น
   browser อยู่บน host นอก network นี้ จึงเข้าผ่าน port ที่ publish (`localhost:8080`) แล้วให้ nginx proxy ต่อไปยัง `backend:3000`

2. **`down` vs `down -v`**

- `down` หยุดและลบ containers / networks ของ project แต่ **เก็บ named volumes**
- `down -v` ลบ volumes ด้วย → ข้อมูล Postgres หาย
  ห้ามใช้ `-v` กับข้อมูลที่ยังต้องการเก็บ (โดยเฉพาะ shared lab machine)

3. **แชร์โดยไม่ส่งรหัสผ่าน**
   เก็บค่าตัวอย่างใน `.env.example` และให้แต่ละคนคัดลอกเป็น `.env` (ถูก gitignore)
   หรือใช้ Docker secrets / password manager ของทีมสำหรับค่าจริง
