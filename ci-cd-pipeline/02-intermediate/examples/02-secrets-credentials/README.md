# 02 — Secrets & Credentials

เปรียบเทียบการจัดการความลับระหว่าง GitHub Actions กับ Jenkins

| ไฟล์                                                   | platform                                    |
| ------------------------------------------------------ | ------------------------------------------- |
| [`github-secrets.yml`](./github-secrets.yml)           | GitHub Actions + `secrets.*` + environment  |
| [`Jenkinsfile.credentials`](./Jenkinsfile.credentials) | Jenkins `credentials()` / `withCredentials` |

## ตั้งค่าก่อนรัน

### GitHub

สร้าง secrets (ตัวอย่างชื่อ):

- `DEMO_API_TOKEN` — ค่าอะไรก็ได้สำหรับ lab (อย่าใช้ของจริงบน public log demo)
- (optional) Environment ชื่อ `staging` พร้อม secret เดียวกัน

### Jenkins

สร้าง credentials:

- Secret text id: `demo-api-token`
- Username/password id: `dockerhub-creds` (ถ้าจะลอง login — optional)

> Lab นี้เน้น **รูปแบบการอ้างอิง** ไม่ได้บังคับเรียก API จริง
