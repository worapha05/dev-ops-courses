# Lab ระดับ Beginner — "ShopLite" Static + Compute ที่ Scale ได้

## เป้าหมาย

ออกแบบโครงสร้างคลาวด์สำหรับร้านค้าออนไลน์จำลอง **ShopLite** ที่ต้อง:

1. Host ไฟล์ static (รูปสินค้า) บน Object Storage อย่างปลอดภัย
2. มีเว็บชั้นหน้า (nginx) บน VM ที่ scale ตามโหลด หลาย AZ/zone
3. แยกสิทธิ์ IAM ตามบทบาท (นักพัฒนา / instance / CI) ตาม PoLP
4. แก้ปัญหาเมื่อ infrastructure เชื่อมต่อไม่ได้หรือ permission พัง

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

ShopLite เปิดตัวใน Singapore (`ap-southeast-1` / `asia-southeast1`)
CTO กำหนดข้อกำหนดดังนี้:

> - รูปสินค้าต้องไม่ถูก list ทั้ง bucket จากอินเทอร์เน็ต
> - หน้าเว็บต้องอยู่ได้ถ้า zone เดียวล่ม
> - นักพัฒนาอ่านได้เฉพาะ `public/`
> - ห้ามฝัง AWS/GCP keys ใน AMI หรือ Git

คืนวันศุกร์ ระบบมีอาการ:

- ผู้ใช้เปิดเว็บไม่ได้เป็นพัก ๆ (instance ถูก terminate แล้วขึ้นช้า)
- CI upload รูปแล้วได้ `AccessDenied`
- มีคนเปิด bucket policy `Principal: "*"` เพื่อ "ให้มันเสร็จเร็ว" — คุณต้อง rollback

---

## โจทย์

### ส่วนที่ 1 — ออกแบบ Topology

วาด/อธิบาย (ข้อความหรือ diagram) ให้ครบ:

1. Region + อย่างน้อย 2 AZ/zones
2. Object storage (private) + ทางเข้าที่แนะนำสำหรับ static (CDN/LB)
3. ASG หรือ MIG หลัง Load Balancer (หรืออย่างน้อย multi-instance)
4. Identity: human group, instance role/SA, CI role/SA

เลือกทำ **อย่างน้อย 1 cloud** (AWS หรือ GCP) ให้จบ end-to-end — แนะนำทำทั้งคู่ถ้ามีเวลา

### ส่วนที่ 2 — Infrastructure as Code / CLI

สร้างไฟล์ภายใต้ folder งานของคุณ (หรือแก้จาก `src/`):

**AWS อย่างน้อย:**

- S3: Block Public Access + versioning + lifecycle
- IAM Group policy อ่านได้เฉพาะ `public/*`
- Launch Template + ASG ≥ 2 instances คนละ subnet/AZ
- Instance Profile อ่าน S3 ได้ (ไม่มี long-lived key)

**GCP อย่างน้อย:**

- GCS: uniform access + public access prevention + lifecycle
- Custom role / SA สำหรับ VM อ่าน object
- Instance Template + MIG size ≥ 2
- Firewall อนุญาต port เว็บเฉพาะ tag ที่เกี่ยวข้อง

### ส่วนที่ 3 — จำลอง Incident & แก้ปัญหา

แก้สถานการณ์ต่อไปนี้ (เขียนขั้นตอน + คำสั่ง):

| #   | อาการ                                                                         | สิ่งที่ต้องหา                                 |
| --- | ----------------------------------------------------------------------------- | --------------------------------------------- |
| A   | `AccessDenied` เมื่อ `aws s3 cp` / `gcloud storage cp` ไปที่ `public/img.png` | policy/role ผิดหรือยังไม่ attach              |
| B   | Health check fail ทั้งกลุ่มหลัง deploy                                        | path `/healthz`, SG/firewall, startup script  |
| C   | มี bucket policy/IAM member ที่เปิด public ทั้งใบ                             | ลบ/บล็อก public แล้วยืนยันด้วย CLI            |
| D   | Instance ใหม่ขึ้นแต่แอปเรียก metadata/API ไม่ได้                              | IMDSv2 / SA scopes / missing instance profile |

### ส่วนที่ 4 — Secrets & Environment ที่ปลอดภัย

1. คัดลอก `src/env/.env.example` → `.env` แล้วใส่ค่าจริงเฉพาะเครื่องคุณ
2. อธิบายว่าทำไม **ห้าม** commit `.tfvars` ที่มี secrets และทำไมใช้ `terraform.tfvars.example` แทน
3. แสดงคำสั่งตั้ง `AWS_PROFILE` / `gcloud config` โดยไม่ echo secret ลง log

---

## เกณฑ์ตรวจ

- [ ] Bucket ไม่ public และมี lifecycle
- [ ] Compute กระจายอย่างน้อย 2 AZ/zone
- [ ] IAM แยก human / machine และจำกัด prefix
- [ ] มีขั้นตอน cleanup (`destroy` / delete) ชัดเจน
- [ ] บันทึกคำสั่งตรวจ incident A–D ได้

---

## เฉลยวิธีคิด (อ่านหลังทำ)

### แนวคิดสถาปัตยกรรม

```text
Users → (แนะนำ) CDN
  │
  ├─ static objects ← private bucket (OAC / backend IAM)
  │
  └─ origin web ← ALB/HTTP LB
    ├─ VM AZ-a
    └─ VM AZ-b
     │
    Instance Role / SA → read bucket
```

**ทำไมไม่เปิด bucket public?**
เพราะควบคุมและ audit ยาก, เสี่ยง data leak, และผิด PoLP — CDN/LB เป็นจุด enforce ที่ดีกว่า

**ทำไม ASG/MIG?**
แทนที่ "ซ่อม VM ทีละเครื่อง" ด้วย "แทนที่เครื่องที่ไม่ healthy" อัตโนมัติ

### โครงสร้างไฟล์เฉลย

ดู [`lab/solution/`](./lab/solution/)

```text
lab/solution/
├── NOTES.md
├── cli/
│ ├── diagnose-accessdenied.sh
│ └── lockdown-public-bucket.sh
└── terraform/
 ├── aws/ # ชุดย่อที่ตอบโจทย์ ShopLite
 └── gcp/
```

### script สำคัญในเฉลย

- `diagnose-accessdenied.sh` — ตรวจ caller identity + จำลองสิทธิ์
- `lockdown-public-bucket.sh` — ปิด public access และลบ policy อันตราย

รายละเอียดวิธีคิดเพิ่มเติมอยู่ใน [`lab/solution/NOTES.md`](./lab/solution/NOTES.md)

### Cleanup

```bash
cd lab/solution/terraform/aws # หรือ gcp
terraform destroy -auto-approve
```
