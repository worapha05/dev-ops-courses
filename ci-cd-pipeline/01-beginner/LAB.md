# Lab ระดับ Beginner — Pipeline แรกของทีม “NovaPay”

## เป้าหมาย

สร้างระบบตรวจคุณภาพอัตโนมัติสำหรับ API เล็ก ๆ ของ startup ชำระเงินจำลอง **NovaPay**:

- เขียน **GitHub Actions** ให้รัน lint + test เมื่อมี PR / push
- ติดตั้ง **Jenkins ด้วย Docker** และสร้าง **Freestyle job** ที่รันชุดคำสั่งเดียวกัน
- ออกแบบ trigger และ env ให้ชัดเจนตามสถานการณ์

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

ทีม NovaPay มี repo ที่มี folder `sample-app/` (ใช้ของ bootcamp นี้ได้)
นักพัฒนา 4 คน push ทับกันบ่อย และเคยปล่อย bug ที่ `add()` รับ string แล้วได้ผลผิด

CTO กำหนด Definition of Done ใหม่:

> “ห้าม merge PR เข้า `main` ถ้า lint หรือ unit test ไม่ผ่าน”

และอยากมี Jenkins ภายในสำหรับทีมที่ยังไม่คุ้น GitHub Actions

---

## โจทย์

### ส่วนที่ 1 — GitHub Actions CI

สร้างไฟล์:

```text
.github/workflows/novapay-ci.yml
```

ข้อกำหนด:

1. Trigger เมื่อ `push` และ `pull_request` ไปที่ branch `main`
2. รองรับ `workflow_dispatch` (ให้กดรันมือได้)
3. มี job ชื่อ `quality` บน `ubuntu-latest`
4. Steps อย่างน้อย:

- `actions/checkout@v4`
- `actions/setup-node@v4` ใช้ Node **20**
- `npm install` ใน `sample-app`
- `npm run lint`
- `npm test`

5. ตั้ง `env` ระดับ job: `APP_ENV: ci`
6. ใน step ใด step หนึ่ง `echo` ค่า `${{ github.sha }}` และ `${{ github.event_name }}` เพื่อให้ตรวจ log ได้

### ส่วนที่ 2 — แยก job (optional แต่แนะนำ)

แยกเป็น 2 jobs:

- `lint`
- `test`

ให้ `test` ใช้ `needs: [lint]` เพื่อ fail fast

### ส่วนที่ 3 — Jenkins Freestyle

1. รัน Jenkins จาก `docker compose up -d` ของ bootcamp
2. สร้าง Freestyle job ชื่อ `novapay-freestyle-ci`
3. Build step รัน lint + test ของ `sample-app` ให้ผ่าน
4. ถ่าย/จด Console Output ว่า test ผ่านกี่เคส (หรืออย่างน้อยเห็น `lint ok` และผลทดสอบ)

> ถ้า agent ยังไม่มี Node — ติดตั้งใน container หรือใช้เครื่อง host ที่มี Node แล้วชี้ workspace ตามที่คุณจัดได้ในแล็บนี้
> จุดประสงค์คือเข้าใจการตั้ง Freestyle ไม่ใช่ทำ production agent hardening

### ส่วนที่ 4 — คำถามคิด (ตอบใน PR description หรือไฟล์ `NOTES.md`)

1. CI ของ NovaPay ตอนนี้เป็น Continuous Delivery หรือยัง? ทำไม?
2. ทำไม Freestyle อย่างเดียวไม่พอในระยะยาว?
3. ถ้าต้องการรัน CI เฉพาะเมื่อไฟล์ใน `sample-app/` เปลี่ยน ต้องแก้อะไร?

---

## เกณฑ์ผ่าน

- [ ] Workflow YAML ถูกต้องตามข้อกำหนดส่วนที่ 1
- [ ] (ถ้าทำส่วนที่ 2) `test` รอ `lint` ด้วย `needs`
- [ ] Jenkins Freestyle รัน lint+test สำเร็จอย่างน้อย 1 ครั้ง
- [ ] ตอบคำถามส่วนที่ 4 ได้
- [ ] ไม่มี secret ถูก hardcode ใน YAML

---

## คำใบ้

- ดูตัวอย่าง [`examples/02-github-actions-basics/ci.yml`](./examples/02-github-actions-basics/ci.yml)
- ดู env/triggers ที่ [`examples/03-github-actions-env-vars/`](./examples/03-github-actions-env-vars/)
- Freestyle guide: [`examples/04-jenkins-docker-setup/freestyle-guide.md`](./examples/04-jenkins-docker-setup/freestyle-guide.md)

---

## เฉลย

อยู่ที่ [`lab/solution/`](./lab/solution/) — เปิดเมื่อทำเองแล้วเท่านั้น
