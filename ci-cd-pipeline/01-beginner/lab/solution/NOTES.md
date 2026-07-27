# เฉลยคำถามคิด — Lab Beginner

## 1. CI ของ NovaPay ตอนนี้เป็น Continuous Delivery หรือยัง?

ยังไม่ใช่ — ตอนนี้มีแค่ **Continuous Integration** (ตรวจคุณภาพอัตโนมัติ)
ยังไม่มีขั้น package/deploy ไป staging หรือ production และยังไม่มี "พร้อมปล่อยได้ตลอด" ในความหมายของ Delivery

## 2. ทำไม Freestyle อย่างเดียวไม่พอในระยะยาว?

- Config อยู่ใน Jenkins UI ไม่ได้อยู่ใน Git → review/rollback ยาก
- Reproduce บนเครื่องอื่น/instance ใหม่ลำบาก
- ขาดความสอดคล้องกับแนว Pipeline as Code ที่ทีมใช้กับ GitHub Actions ได้แล้ว

## 3. ถ้ารัน CI เฉพาะเมื่อ `sample-app/` เปลี่ยน

เพิ่ม `paths` ใต้ `push` / `pull_request` เช่น:

```yaml
on:
  push:
    branches: [main]
    paths:
      - '01-beginner/sample-app/**'
      - '.github/workflows/**'
  pull_request:
    branches: [main]
    paths:
      - '01-beginner/sample-app/**'
      - '.github/workflows/**'
```
