# Lab ระดับ Expert — Delivery ระดับองค์กรของ “AetherBank”

## เป้าหมาย

ออกแบบและเขียน pipeline ครบวงจรสำหรับธนาคารดิจิทัลจำลอง **AetherBank**:

- Build Docker image → สแกนด้วย Trivy → (จำลอง) push registry
- Deploy แบบมี **staging → manual approval → production**
- รองรับกลยุทธ์ **Blue-Green หรือ Canary** (อย่างน้อยหนึ่งแบบใน workflow)
- ใส่ **dependency caching** และอธิบายการ optimize
- มี **Jenkinsfile** ที่มี `input` gate คู่ขนานแนวคิดเดียวกัน

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

AetherBank จะปล่อย microservice `sample-app` เป็น customer-facing API
ข้อกำหนดจาก Security & SRE:

1. ห้าม deploy image ที่ยังไม่ผ่าน unit test + Trivy (HIGH/CRITICAL)
2. Production ต้องมี human approval ทุกครั้ง
3. ใช้ tag แบบ `sha-<commit>` ไม่ใช้ `latest` เป็นแหล่งความจริง
4. Rollback ต้องอธิบายได้ภายใน 5 นาที (ผ่าน blue-green หรือ canary abort)
5. CI ต้องเร็วขึ้นด้วย cache และยกเลิก run เก่าของ PR เดียวกันได้

CTO อนุญาตให้ส่วน cloud จริงเป็น **จำลองด้วย steps + comments** ได้
แต่โครง jobs/stages ต้อง production-shaped

---

## โจทย์

### ส่วนที่ 1 — Secure GitHub Actions pipeline

สร้าง `.github/workflows/aetherbank-delivery.yml` ที่มี jobs อย่างน้อย:

| Job                 | ความต้องการ                                                                                                    |
| ------------------- | -------------------------------------------------------------------------------------------------------------- |
| `quality`           | lint + test ของ `sample-app` พร้อม npm cache + concurrency                                                     |
| `sast`              | Trivy scan แบบ `fs` บน `sample-app`, `exit-code: 1` สำหรับ HIGH,CRITICAL                                       |
| `build`             | `docker build` image `aetherbank/sample-app:sha-${{ github.sha }}` (push=false ก็ได้ใน lab) + Trivy image scan |
| `deploy-staging`    | จำลอง deploy + smoke `/health` (เฉพาะ `main`)                                                                  |
| `deploy-production` | ใช้ `environment: production` (รอ reviewers) แล้วจำลอง **blue-green cutover หรือ canary promote**              |

เงื่อนไขเพิ่ม:

- `concurrency` สำหรับกัน deploy ชนกันบน production
- ไม่ hardcode cloud credentials — อ้าง `${{ secrets.* }}` แม้ใน lab จะยังไม่สร้างค่าจริงก็ได้ใน comment/env

### ส่วนที่ 2 — Jenkins parallel path

สร้าง `Jenkinsfile` ที่:

1. ทดสอบด้วย Node image
2. Build docker image (ถ้า native docker ใช้ได้) หรือ stage จำลอง
3. `input` ก่อน production พร้อม timeout
4. post แจ้ง aborted/failure

### ส่วนที่ 3 — เอกสารปฏิบัติการ

เขียน `RUNBOOK.md` สั้น ๆ ครอบคลุม:

1. ลำดับ jobs ตอนปล่อย
2. ใครต้อง approve production
3. วิธี rollback (blue→กลับ หรือ abort canary)
4. เมื่อ Trivy fail ต้องทำอะไร

### ส่วนที่ 4 — คำถามคิด

1. ทำไมต้อง deploy **digest/tag เดียว** จาก staging ไป production?
2. OIDC ดีกว่า JSON key ระยะยาวอย่างไร?
3. ถ้า canary ผ่าน แต่ DB migration irreversible — ความเสี่ยงคืออะไร?

---

## เกณฑ์ผ่าน

- [ ] Workflow มี quality → sast → build/scan → staging → production approval
- [ ] มี Trivy อย่างน้อยหนึ่งจุดที่ทำให้ pipeline fail ได้
- [ ] มี caching และ concurrency
- [ ] มี Jenkinsfile พร้อม `input`
- [ ] มี RUNBOOK.md
- [ ] ไม่มี secret จริงถูก commit

---

## คำใบ้

- [`examples/01-docker-registry-deploy/`](./examples/01-docker-registry-deploy/)
- [`examples/02-blue-green-canary/`](./examples/02-blue-green-canary/)
- [`examples/03-caching-optimization/`](./examples/03-caching-optimization/)
- [`examples/04-sast-security/secure-pipeline.yml`](./examples/04-sast-security/secure-pipeline.yml)

---

## เฉลย

[`lab/solution/`](./lab/solution/)
