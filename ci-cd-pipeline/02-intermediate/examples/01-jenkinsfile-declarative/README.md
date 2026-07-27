# 01 — Declarative Jenkinsfile

ไฟล์ [`Jenkinsfile`](./Jenkinsfile) เป็นตัวอย่าง Declarative ที่:

- ใช้ `agent { docker { image 'node:20-bookworm' } }`
- มี stages: Checkout → Install → Lint → Test → Archive
- มี `post` สำหรับ always/success/failure
- มี `options { timestamps(); timeout(time: 15, unit: 'MINUTES') }`

## วิธีลอง

1. วาง `Jenkinsfile` ที่ root ของ repo (หรือชี้ path ใน Pipeline job)
2. สร้าง Pipeline job แบบ **Pipeline script from SCM**
3. กด Build แล้วดู Stage View
