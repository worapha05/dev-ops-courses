# คู่มือ Freestyle Project — Beginner

## 1) สร้าง Job

1. จาก Dashboard กด **New Item**
2. ชื่อ: `bootcamp-sample-freestyle`
3. เลือก **Freestyle project** → OK

## 2) Source Code

ตัวเลือกเรียน:

**A. Git (แนะนำถ้ามี remote)**

- SCM → Git
- Repository URL → URL ของ fork/repo
- Branch → `*/main`

**B. None + Execute shell ที่ clone เอง** (ทดลองเร็ว)

## 3) Build Triggers

สำหรับ lab นี้เริ่มด้วย **ไม่ต้องเปิด trigger** — กด **Build Now** พอ
เมื่อพร้อม ค่อยลอง:

- **Poll SCM**: `H/10 * * * *`
- หรือตั้ง GitHub webhook ชี้มาที่ `http://<jenkins-host>:8080/github-webhook/`

## 4) Build Step

**Add build step → Execute shell** แล้ววาง:

```bash
set -euo pipefail

# ถ้า job checkout มาที่ workspace root ที่มี sample-app
cd 01-beginner/sample-app

# ติดตั้ง Node ใน agent — ถ้า image Jenkins ยังไม่มี node
# แนวทางเรียน: ใช้ agent ที่มี node หรือติดตั้งผ่าน nvm/tooling ของคุณ
node -v
npm -v

npm install
npm run lint
npm test
```

> ถ้า Jenkins container ยังไม่มี Node.js ให้ติดตั้งใน Dockerfile customize
> หรือใช้ Pipeline + Docker agent ในระดับ Intermediate

## 5) ดูผล

- จุดสีบน job = สถานะล่าสุด
- เปิด build number → **Console Output** อ่าน log

## 6) สิ่งที่ควรสังเกต

Freestyle เก็บ config ใน Jenkins home — **ยังไม่ใช่ Pipeline as Code**
เป้าหมาย Beginner คือเข้าใจ UI และ trigger; ระดับถัดไปจะย้ายมา Jenkinsfile
