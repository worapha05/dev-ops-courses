# Lab ระดับ Intermediate — "PayFlow API" ที่ Scale, Private DB และ Secrets

## เป้าหมาย

ออกแบบและแก้ปัญหา platform ชำระเงินจำลอง **PayFlow**:

1. Deploy API แบบ serverless container (ECS/Fargate หรือ Cloud Run)
2. ใช้ Managed PostgreSQL แบบ HA ใน private subnet/IP
3. ดึง credentials จาก Secrets Manager / Secret Manager — ไม่ hardcode
4. ออกแบบ VPC แยก public / app / data และแก้เมื่อ "เชื่อมต่อไม่ได้"

ทำด้วยตัวเองก่อน แล้วเทียบ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

PayFlow รับ webhook จากธนาคารและเสิร์ฟ REST API
SLO: p95 latency < 300ms, availability 99.9% ใน region เดียว

คืน deploy ล่าสุดทำให้:

- Task/Revision ขึ้นไม่สำเร็จ (`CannotPullContainerError` / `Secret access denied`)
- API บาง port เปิดได้แต่ query DB timeout
- มีคน commit `.env` ที่มีรหัสผ่าน DB ขึ้น GitHub — ต้อง rotate ทันที
- Traffic ช่วง flash sale ทำให้ CPU พุ่ง ต้อง scale ออกโดยไม่แตะ DB primary เกินจำเป็น

---

## โจทย์

### ส่วนที่ 1 — ออกแบบเครือข่ายและชั้นบริการ

ส่งมอบ diagram/ข้อความที่ระบุ:

1. CIDR ของ VPC + subnet อย่างน้อย 3 ชั้น × 2 AZ (หรือเทียบเท่า GCP)
2. จุดเข้า public (ALB / Cloud Run URL) และเส้นทางไปแอป private
3. เส้นทางแอป → DB (SG/firewall แบบ least privilege)
4. ตำแหน่ง NAT / Private Google Access และเหตุผลด้านต้นทุน

### ส่วนที่ 2 — Implement (เลือก AWS หรือ GCP หรือทั้งคู่)

อย่างน้อยต้องมี:

- [ ] VPC ตามแบบในส่วนที่ 1
- [ ] Secrets ใน manager + IAM ให้ runtime อ่านได้เท่านั้น
- [ ] RDS Multi-AZ หรือ Cloud SQL Regional HA (private)
- [ ] ECS Service บน Fargate **หรือ** Cloud Run พร้อม `/healthz`
- [ ] Autoscaling ตาม CPU หรือ concurrency
- [ ] แอปจาก `src/app/` (build/push image ของคุณเอง)

### ส่วนที่ 3 — Incident Response

เขียน runbook แก้:

| รหัส  | อาการ                                                         |
| ----- | ------------------------------------------------------------- |
| INC-1 | Container pull ไม่ได้จาก private subnet                       |
| INC-2 | `AccessDeniedException` ตอน inject secret                     |
| INC-3 | DB connection timeout จากแอป                                  |
| INC-4 | พบ secret ใน Git — ต้อง rotate + redeploy โดยไม่ downtime นาน |

### ส่วนที่ 4 — Scale Design

อธิบายว่าจะ scale ชั้น API อย่างไรเมื่อ RPS ×3 โดย:

- ไม่เปิด public ให้ DB
- ไม่เพิ่มสิทธิ์ IAM กว้างขึ้น
- ระบุ metric ที่ใช้ (CPU, request count, concurrency)

---

## เกณฑ์ตรวจ

- [ ] DB ไม่มี public IP / `publicly_accessible = false`
- [ ] Secret ไม่ปรากฏใน image หรือ repo
- [ ] App รับ traffic ผ่าน LB หรือ Cloud Run HTTPS
- [ ] มี script/ขั้นตอน diagnose networking
- [ ] มีแผน rotate secret

---

## เฉลยวิธีคิด (อ่านหลังทำ)

### Topology อ้างอิง

```text
Internet → ALB (public subnets) → Fargate tasks (private)
     │ SG: 8080 from ALB only
     ▼
     RDS Multi-AZ (data subnets)
     ▲
    Secrets Manager ← Execution Role
```

GCP:

```text
Internet → Cloud Run → Direct VPC (private subnet) → Cloud SQL private IP
  │
  Secret Manager (secretAccessor on runtime SA)
```

### INC-1 Pull image ไม่ได้

สาเหตุพบบ่อย: ไม่มี NAT / ไม่มี ECR VPC endpoint / image private แต่ execution role ไม่มีสิทธิ์
แก้: เปิด NAT สำหรับ lab หรือเพิ่ม interface endpoints + ตรวจ policy

### INC-2 Secret denied

แยก **execution role** (ดึง secret ตอน start) กับ **task role** (สิทธิ์ตอนรัน)
GCP: ต้อง `roles/secretmanager.secretAccessor` บน runtime SA

### INC-3 DB timeout

ตรวจ: SG ต้นทางเป็น SG ของแอป (ไม่ใช่ CIDR กว้าง), route table ของ data subnet, DNS ของ RDS, Cloud SQL Auth / private IP

### INC-4 Secret หลุด

1. Rotate ทันทีใน manager (+ เปลี่ยน DB password)
2. Invalidate version เก่า
3. Force new deployment ให้ task/revision ดึง version ใหม่
4. ลบออกจาก git history ตามนโยบายองค์กร + สแกน key ที่เกี่ยวข้อง

รายละเอียดไฟล์เฉลย: [`lab/solution/NOTES.md`](./lab/solution/NOTES.md)
