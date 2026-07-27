# เฉลยแนวคิด — ShopLite Beginner Lab

## ส่วนที่ 1 — Topology ที่ผ่านเกณฑ์

| ชั้น        | AWS                                     | GCP                                  |
| ----------- | --------------------------------------- | ------------------------------------ |
| Static      | S3 private + (ขั้นถัดไป) CloudFront OAC | GCS + public access prevention + CDN |
| Compute     | ASG 2 AZ + Launch Template + IMDSv2     | MIG 2+ + template + SA               |
| Human IAM   | Group + prefix-scoped policy            | Group/Workspace + custom role        |
| Machine IAM | Instance profile → S3 read              | VM SA → objectViewer บน bucket       |

จุดตัดสินใจสำคัญ: **public ingress มีได้ที่ LB/CDN เท่านั้น** ไม่ใช่ที่ bucket

## ส่วนที่ 2 — ทำไม Terraform ชุดเฉลยถึงผ่าน

ไฟล์ใน `terraform/aws` และ `terraform/gcp` ย่อจาก `src/terraform` โดยเน้น:

1. Block public / public access prevention
2. Lifecycle ประหยัดค่า
3. Multi-instance
4. Role/SA แยกจาก human credentials

## ส่วนที่ 3 — Runbook Incident

### A — AccessDenied ตอน upload

```bash
# AWS
aws sts get-caller-identity --profile "$AWS_PROFILE"
aws iam list-attached-group-policies --group-name ccp-bootcamp-devs
# policy ตัวอย่างใน lab อ่านได้อย่างเดียว — upload ต้องมี s3:PutObject แยกสำหรับ CI role

# GCP
gcloud auth list
gcloud storage buckets get-iam-policy gs://BUCKET
```

แนวแก้: สร้าง **CI role แยก** ที่มี `s3:PutObject` / `storage.objects.create` เฉพาะ `public/*` — อย่าให้ dev group เขียนได้ทั้งใบ

### B — Health check แดง

1. SSH/serial console ดูว่า nginx ขึ้นหรือยัง
2. `curl -I http://127.0.0.1/healthz`
3. ตรวจ SG/firewall อนุญาต port จาก LB ไม่ใช่แค่จาก internet โดยตรง (ถ้ามี LB)
4. เพิ่ม `health_check_grace_period` / `initial_delay_sec` ถ้า startup ช้า

### C — มีคนเปิด public ทั้ง bucket

รัน `cli/lockdown-public-bucket.sh` แล้วยืนยัน:

```bash
aws s3api get-public-access-block --bucket BUCKET
# หรือ
gcloud storage buckets describe gs://BUCKET --format='yaml(publicAccessPrevention,iamConfiguration)'
```

### D — Metadata / API จาก instance ไม่ได้

- AWS: บังคับ IMDSv2 ใน launch template; ตรวจว่ามี instance profile
- GCP: ตรวจ SA ที่ผูก VM และ scopes; หลีกเลี่ยง SA ที่ไม่มีสิทธิ์

## ส่วนที่ 4 — Environment

- `.env` และ `*.tfvars` จริงอยู่ใน `.gitignore`
- ใช้ profile/SSO และ ADC แทนการวาง key ในไฟล์ที่แชร์ได้
- `terraform.tfvars.example` มีแค่ค่าตัวอย่างไม่มี secret

## สิ่งที่มักทำผิด

1. เปิด `0.0.0.0/0` บน SSH พร้อม key อ่อน — lab นี้เลี่ยง SSH สาธารณะโดยเจตนา
2. ใช้สิทธิ์ `AmazonS3FullAccess` / `roles/storage.admin` ในชื่อ "ชั่วคราว" แล้วลืมถอน
3. ลืม destroy หลังเลิก lab
