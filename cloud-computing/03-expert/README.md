# Level 3 — Expert: IaC, High Availability & Multi-Cloud Engineering

ระดับนี้รวมทุกอย่างเป็นระบบที่ **ทำซ้ำได้, ทนทานข้าม region และวัดผลได้ทั้ง reliability กับต้นทุน**

---

## สารบัญ

1. [Infrastructure as Code ด้วย Terraform](#1-infrastructure-as-code-ด้วย-terraform)
2. [Resilience & Multi-Region Design](#2-resilience--multi-region-design)
3. [Observability](#3-observability)
4. [Cost Management & FinOps](#4-cost-management--finops)
5. [เปรียบเทียบ AWS vs GCP (ระดับ Expert)](#5-เปรียบเทียบ-aws-vs-gcp-ระดับ-expert)
6. [Best Practices](#6-best-practices)
7. [โครงสร้างโค้ด](#7-โครงสร้างโค้ด)

---

## 1. Infrastructure as Code ด้วย Terraform

### 1.1 ทำไมต้อง Modules + Remote State

| ปัญหาเมื่อไม่มี               | ผลลัพธ์                              |
| ----------------------------- | ------------------------------------ |
| Copy-paste `main.tf` ทีละ env | Drift, แก้บั๊กไม่ครบ                 |
| State บน laptop               | Conflict, ไฟล์หาย = orphan resources |
| ไม่มี locking                  | สองคน apply พร้อมกัน → state เสีย    |

### 1.2 โครง Module ที่ดี

```text
modules/
  network/ ← VPC, subnets, NAT
  compute/ ← ASG/MIG หรือ interface สำหรับ container service
  storage/ ← bucket + lifecycle + encryption
  database/ ← RDS/Cloud SQL HA
environments/
  dev/
  staging/
  prod/
```

หลักการ:

- Module รับ **variables ที่จำเป็นเท่านั้น** และมี validation
- Output สิ่งที่ module อื่นต้องใช้ (subnet IDs, SG IDs) — ไม่ output secrets
- ใช้ `terraform.tfvars` ต่อ env + remote backend คนละ key

### 1.3 Remote Backend ที่ปลอดภัย

**AWS:** S3 + DynamoDB lock (หรือ S3 native lock ตาม version) + encryption + block public
**GCP:** GCS backend + object versioning + IAM จำกัดใครรัน CI

```hcl
terraform {
  backend "s3" {
    bucket         = "org-tfstate-prod"
    key            = "ccp/prod/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "tfstate-locks"
    encrypt        = true
  }
}
```

ตัวอย่างไฟล์: `src/terraform/backend/`

### 1.4 Drift Detection

```bash
terraform plan -detailed-exitcode
# 0 = ไม่มีเปลี่ยน, 2 = มี drift/change, 1 = error
```

ใน CI: รัน `plan` ทุกคืน แล้วแจ้ง Slack เมื่อ exit code = 2
ห้ามแก้ resource สำคัญมือใน console โดยไม่มี change ticket — หรือยอมรับแล้ว `import` กลับ

### 1.5 Multi-Cloud ด้วย Terraform

แนวทางที่แนะนำสำหรับ bootcamp นี้:

1. **Module แยกต่อ cloud** (ไม่พยายาม abstraction ชั้นเดียวบังคับทุกอย่าง)
2. ชั้น "product" เรียก module AWS/GCP ตาม workspace
3. ใช้ naming/label มาตรฐานร่วม (`project`, `env`, `owner`)

โค้ด: `src/terraform/modules/*`, `src/terraform/multi-cloud/`

---

## 2. Resilience & Multi-Region Design

### 2.1 กลยุทธ์ Disaster Recovery

| กลยุทธ์                           | RPO / RTO โดยประมาณ | ต้นทุน   | ใช้เมื่อ                     |
| --------------------------------- | ------------------- | -------- | ---------------------------- |
| Backup & Restore                  | ชั่วโมง–วัน         | ต่ำ      | ระบบทน downtime ได้          |
| Pilot Light                       | นาที–ชั่วโมง        | กลาง     | ต้องการอุ่น core ไว้         |
| **Warm Standby (Active-Passive)** | นาที                | กลาง–สูง | business critical            |
| **Active-Active**                 | ใกล้ศูนย์           | สูง      | global UX / regulated uptime |

### 2.2 Cross-Region Data

| ข้อมูล       | AWS                                           | GCP                               |
| ------------ | --------------------------------------------- | --------------------------------- |
| Object       | S3 CRR                                        | Dual-region / multi-region bucket |
| DB           | RDS read replica cross-region / Aurora Global | Cloud SQL replica / Spanner       |
| DNS failover | Route 53 health checks + failover             | Cloud DNS + multi-region LB       |

### 2.3 Global Traffic Orchestration

```text
User
  → Route 53 / Global HTTPS LB
  → Region A (active)
  → Region B (active หรือ standby)
```

จุดออกแบบ:

- Health check ต้องสะท้อน dependency จริง (DB/cache) ไม่ใช่แค่ process up
- Sticky sessions ระวังเมื่อ active-active — ควรเป็น stateless + external session store
- ทดสอบ failover **เป็นประจำ** ไม่ใช่รอวันที่พัง

Runbook ตัวอย่าง: ใน Lab และ `lab/solution/runbooks/`

---

## 3. Observability

เสาหลักสามอย่าง: **Logs, Metrics, Traces**

| เสา     | AWS                     | GCP                              |
| ------- | ----------------------- | -------------------------------- |
| Logs    | CloudWatch Logs         | Cloud Logging                    |
| Metrics | CloudWatch Metrics      | Cloud Monitoring                 |
| Traces  | X-Ray                   | Cloud Trace                      |
| Dashboards / Alerts | CloudWatch Alarms + SNS | Alerting + Notification channels |

### แนวปฏิบัติ Expert

1. Structured JSON logs + correlation/trace id
2. RED/USE metrics สำหรับบริการ (Rate, Errors, Duration)
3. Alert ที่ actionable — ไม่ alert ทุก CPU spike
4. Sampling traces ใน production ให้สมดุลค่าใช้จ่าย
5. รวม log สำคัญไปที่ central sink (org-level) สำหรับ audit

script/config: `src/observability/`

---

## 4. Cost Management & FinOps

FinOps = วัฒนธรรมร่วมระหว่าง Engineering, Finance, Product เพื่อตัดสินใจบนข้อมูลต้นทุน

### กลยุทธ์ที่ใช้บ่อย

| กลยุทธ์                     | รายละเอียด                                      |
| --------------------------- | ----------------------------------------------- |
| Right-sizing                | ลด instance ที่ CPU p95 ต่ำต่อเนื่อง            |
| Spot / Preemptible          | งาน batch, stateless ที่ทน interrupt            |
| Savings Plans / CUD         | workload คงที่                                   |
| Storage lifecycle           | ตามระดับ Beginner แต่บังคับใน prod              |
| ปิด idle NAT/LB             | resource ที่แพงและลืมลบหลัง lab                 |
| Budgets + anomaly detection | แจ้งเตือนวันแรกของเดือนไม่พอ — ต้องมี real-time |

script: `src/finops/`

---

## 5. เปรียบเทียบ AWS vs GCP (ระดับ Expert)

| หัวข้อ           | AWS                           | GCP                                     |
| ---------------- | ----------------------------- | --------------------------------------- |
| Global LB        | Route 53 + ALB/NLB ต่อ region | Global External HTTPS LB native Anycast |
| Org hierarchy    | OUs + Accounts                | Folders + Projects                      |
| IaC native       | CloudFormation / CDK          | Deployment Manager / Config Connector   |
| Multi-cloud IaC  | Terraform เป็นกลางที่สุด      | เช่นเดียวกัน                            |
| Observability UX | ลึกแต่กระจายหลายคอนโซล        | มักรวมใน Operations suite               |

**คำแนะนำสถาปนิก:** เลือก primary cloud ตามทีมและ ecosystem แล้วใช้ Terraform + มาตรฐาน observability ให้ทำงานร่วมกันได้ — อย่า multi-cloud เพื่อความเท่หากทีมยังไม่พร้อม ops

---

## 6. Best Practices

1. **State แยกต่อ env** และจำกัด IAM ใคร `terraform apply` ได้บน prod
2. **Policy as Code** (OPA/Sentinel/Checkov) สแกนก่อน apply
3. **Blue/green หรือ canary** สำหรับเปลี่ยน multi-region
4. **Game day** จำลอง region failure อย่างน้อยรายไตรมาส
5. **Cost allocation tags** บังคับผ่าน organization policy / tag policy
6. **เอกสาร ADR** ทุกครั้งที่เลือก Active-Active แทน Warm Standby

---

## 7. โครงสร้างโค้ด

```text
03-expert/
├── README.md
├── LAB.md
├── src/
│   ├── env/.env.example
│   ├── terraform/
│   │   ├── backend/  # ตัวอย่าง remote state buckets
│   │   ├── modules/  # network, compute, storage, database
│   │   ├── aws/      # env ตัวอย่างประกอบ modules
│   │   ├── gcp/
│   │   └── multi-cloud/ # orchestrate ทั้งสองฝั่ง
│   ├── cli/{aws,gcp}/
│   ├── observability/
│   └── finops/
└── lab/solution/
    ├── runbooks/
    ├── terraform/
    └── cli/
```
