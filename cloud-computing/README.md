# Cloud Computing Platforms Bootcamp — Zero to Expert

bootcamp เรียนรู้ **Cloud Architecture บน AWS และ GCP** แบบครบวงจร
เน้น **โมเดลบริการคลาวด์, Compute/Storage/IAM, Containers & Managed DB, Networking, Secrets**
และปิดท้ายด้วย **Infrastructure as Code (Terraform), Multi-Region DR, Observability และ FinOps**

---

## เป้าหมายของหลักสูตร

เมื่อจบหลักสูตรนี้ คุณจะสามารถ:

- อธิบาย **Shared Responsibility Model**, Regions/AZs และความต่างของ **IaaS / PaaS / FaaS** ได้ชัดเจน
- เปรียบเทียบสถาปัตยกรรมหลักของ **AWS vs GCP** และเลือกบริการที่เหมาะสมกับโจทย์
- สร้างและจัดการ **VM (EC2 / Compute Engine)**, Object Storage, IAM ตาม **Principle of Least Privilege**
- Deploy API แบบ serverless container (**ECS/Fargate vs Cloud Run**) พร้อม Managed DB และ Secrets
- ออกแบบ **VPC / Subnet / Firewall** สำหรับ workload ที่ scale ได้และแยก public/private ชัดเจน
- Automate multi-cloud ด้วย **Terraform modules + remote state** และออกแบบ **DR / Observability / FinOps**

---

## โครงสร้างหลักสูตร

| Level            | folder                                   | หัวข้อหลัก                                                | เวลาแนะนำ   |
| ---------------- | ---------------------------------------- | --------------------------------------------------------- | ----------- |
| 1 — Beginner     | [`01-beginner/`](./01-beginner/)         | Cloud paradigms, EC2/GCE, S3/GCS, IAM basics              | 1–2 สัปดาห์ |
| 2 — Intermediate | [`02-intermediate/`](./02-intermediate/) | ECS/Fargate & Cloud Run, RDS/Cloud SQL, Secrets, VPC      | 2–3 สัปดาห์ |
| 3 — Expert       | [`03-expert/`](./03-expert/)             | Terraform modules, Multi-region DR, Observability, FinOps | 3–4 สัปดาห์ |

แต่ละระดับประกอบด้วย:

1. **`README.md`** — ทฤษฎีเชิงลึกภาษาไทย เปรียบเทียบ AWS vs GCP และ Best Practices
2. **`src/`** — Terraform, CLI scripts (`aws` / `gcloud`) และการตั้งค่า environment ที่ปลอดภัย
3. **`LAB.md`** — โจทย์สถานการณ์จริงพร้อมเฉลยวิธีคิด โครงสร้างไฟล์ และ script

---

## ข้อกำหนดเบื้องต้น

- ความรู้พื้นฐาน Linux, networking (IP, DNS, HTTP) และ Git
- บัญชีทดลอง **AWS Free Tier** และ/หรือ **GCP Free Trial** (ใช้ sandbox แยกจาก production)
- ติดตั้งเครื่องมือต่อไปนี้:

```bash
# CLIs
aws --version      # AWS CLI v2
gcloud --version   # Google Cloud SDK
terraform -version # Terraform >= 1.5

# แนะนำเพิ่ม
docker --version
jq --version
```

### การตั้งค่า Identity เบื้องต้น (อย่า hardcode key ใน repo)

```bash
# AWS — ใช้ profile หรือ SSO แทน long-lived key ถ้าเป็นไปได้
aws configure --profile bootcamp
export AWS_PROFILE=bootcamp

# GCP — login + เลือก project
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default login
```

ดู template environment ที่ปลอดภัยในแต่ละระดับที่ `src/env/.env.example`

---

## วิธีใช้ Bootcamp

1. อ่าน `README.md` ของระดับนั้นให้จบ — โฟกัสที่ **ทำไมเลือกบริการนี้** และ **trade-off**
2. รันตัวอย่างใน `src/` ตามลำดับ (CLI ก่อน แล้วค่อย Terraform)
3. ทำ Lab ใน `LAB.md` **ด้วยตัวเองก่อน** แล้วค่อยดู `lab/solution/`
4. ทำลาย resource หลังทดลองเสมอ (`terraform destroy` / script cleanup) เพื่อควบคุมค่าใช้จ่าย

```bash
cd cloud-computing-platforms

# ตัวอย่าง Beginner — AWS CLI
cd 01-beginner/src/cli/aws && bash setup-s3-static.sh

# ตัวอย่าง Beginner — Terraform (ดู README ใน folder ก่อน)
cd ../../terraform/aws
cp terraform.tfvars.example terraform.tfvars # แก้ค่าให้ตรงบัญชีคุณ
terraform init && terraform plan
```

---

## แผนที่บริการ AWS ↔ GCP (Quick Map)

| ความสามารถ            | AWS                        | GCP                            |
| --------------------- | -------------------------- | ------------------------------ |
| Virtual Machine       | EC2                        | Compute Engine                 |
| Object Storage        | S3                         | Cloud Storage                  |
| IAM                   | IAM Users/Roles/Policies   | IAM + Service Accounts         |
| Serverless Containers | ECS/Fargate                | Cloud Run                      |
| Managed Relational DB | RDS                        | Cloud SQL                      |
| Secrets               | Secrets Manager            | Secret Manager                 |
| VPC / Firewall        | VPC, SG, NACL              | VPC, Firewall Rules            |
| Global DNS / Traffic  | Route 53                   | Cloud DNS + Global LB          |
| Logs / Traces         | CloudWatch, X-Ray          | Cloud Logging, Cloud Trace     |
| IaC                   | CloudFormation / Terraform | Deployment Manager / Terraform |

---

## หลักการความปลอดภัยที่ใช้ตลอดหลักสูตร

1. **Least Privilege** — ให้สิทธิ์เท่าที่จำเป็นและมีอายุสั้น
2. **No secrets in Git** — ใช้ Secrets Manager / Secret Manager / CI secrets
3. **Private by default** — public subnet/LB เฉพาะจุดเข้า; data plane อยู่ใน private
4. **Encrypt in transit & at rest** — TLS + KMS/CMEK
5. **Destroy after lab** — ป้องกัน bill shock

---

## ลำดับการเรียนที่แนะนำ

```text
01-beginner → พื้นฐาน cloud + compute/storage/IAM
 ↓
02-intermediate → containers + DB + secrets + VPC
 ↓
03-expert → Terraform modules + DR + observability + FinOps
```
