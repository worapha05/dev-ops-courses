# Pipeline Design Checklist (Beginner)

- [ ] มี workflow รันบนทุก pull request สู่ `main`
- [ ] มีขั้น lint และ/หรือ unit test
- [ ] ตั้ง `runs-on` / agent ที่ชัดเจน
- [ ] ไม่มีรหัสผ่าน/API key ในไฟล์ที่ commit
- [ ] ชื่อ job สื่อความหมาย (`test`, `lint`)
- [ ] ถ้ามีหลาย job ที่ต้องรอต่อกัน ใช้ `needs` (Actions) หรือ stages ตามลำดับ (Jenkins)
- [ ] ทีมรู้วิธีอ่าน log เมื่อ fail
- [ ] แยก “CI บน PR” กับ “Deploy บน main” อย่างน้อยในใจ (แม้ยังไม่ทำ CD)
