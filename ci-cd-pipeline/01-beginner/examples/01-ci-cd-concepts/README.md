# 01 — CI/CD Concepts

ไฟล์นี้เป็น “แผนที่ความคิด” ก่อนเขียน YAML

## คำถามออกแบบ Pipeline 5 ข้อ

1. **อะไรคือ Definition of Done ของ commit นี้?** (lint? test? build image?)
2. **ใคร/อะไร trigger?** (PR, push main, มือ, schedule)
3. **ต้องใช้ secret อะไร?** (ถ้ายัง Beginner — ยังไม่ใส่ก็ได้)
4. **fail แล้วใครรู้?** (PR check, Slack, email)
5. **deploy หรือยัง?** ถ้ายังไม่พร้อม — หยุดที่ CI

## ตัวอย่างเส้นทางสำหรับ sample-app

```
PR opened
 → checkout
 → setup Node 20
 → npm ci
 → npm run lint
 → npm test
 → (ยังไม่ deploy)
```

## checklist.md

ดู [`checklist.md`](./checklist.md)
