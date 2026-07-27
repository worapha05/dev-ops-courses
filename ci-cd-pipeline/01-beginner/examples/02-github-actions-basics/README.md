# 02 — GitHub Actions Basics

คัดลอก `ci.yml` ไปไว้ที่ root ของ repo ที่ต้องการใช้:

```text
.github/workflows/ci.yml
```

โครงสร้างใน bootcamp นี้สมมติว่า `sample-app/` อยู่ที่ root ของ repo
ถ้าเอาไปใช้ repo จริง ให้ปรับ `working-directory` ให้ตรง

## สิ่งที่ workflow นี้ทำ

1. Checkout โค้ด
2. ติดตั้ง Node.js 20
3. `npm install` ใน `sample-app`
4. รัน lint + test
