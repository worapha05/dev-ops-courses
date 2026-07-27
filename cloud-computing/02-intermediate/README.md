# Level 2 — Intermediate: Containers, Managed Databases, Secrets & VPC

ระดับนี้ยกระดับจาก VM เดี่ยว ๆ ไปสู่ **workload ที่ deploy บ่อย, ข้อมูลที่มี HA, ความลับที่ไม่ฝังในไฟล์ และเครือข่ายที่แยกชั้น**

---

## สารบัญ

1. [Modern Container Orchestration](#1-modern-container-orchestration)
2. [Managed Databases](#2-managed-databases)
3. [Security & Environment Secrets](#3-security--environment-secrets)
4. [Virtual Networking (VPC)](#4-virtual-networking-vpc)
5. [เปรียบเทียบสถาปัตยกรรม AWS vs GCP (ระดับนี้)](#5-เปรียบเทียบสถาปัตยกรรม-aws-vs-gcp-ระดับนี้)
6. [Best Practices](#6-best-practices)
7. [โครงสร้างโค้ด](#7-โครงสร้างโค้ด)

---

## 1. Modern Container Orchestration

### 1.1 ทำไมต้อง Serverless Containers

| แนวทาง                      | ข้อดี                             | ข้อเสีย                      |
| --------------------------- | --------------------------------- | ---------------------------- |
| VM + Docker เอง             | ควบคุมสูง                         | แพตช์ OS, scale ช้า          |
| Kubernetes เต็มรูปแบบ       | ยืดหยุ่นมาก                       | เส้นเรียนรู้สูง, ค่า ops     |
| **ECS/Fargate / Cloud Run** | ไม่จัดการ node, scale ตาม request | จำกัดบาง networking/features |

สำหรับ API ส่วนใหญ่ในองค์กรขนาดเล็ก–กลาง: เริ่มที่ **Fargate หรือ Cloud Run** ก่อน EKS/GKE

### 1.2 AWS ECS on Fargate

แนวคิดหลัก:

```text
ALB (public subnets)
 → Target Group
 → ECS Service (Fargate tasks ใน private subnets)
 → Task Definition (CPU/RAM, image, secrets, env)
 → IAM Task Role (เรียก AWS API)
 → IAM Execution Role (ดึง image + secrets)
```

จุดที่มักสับสน:

- **Task Role** = สิทธิ์ของแอป (อ่าน Secrets, เขียน S3)
- **Execution Role** = สิทธิ์ของ agent ที่ start task (pull ECR, ดึง secret ตอน inject)

### 1.3 GCP Cloud Run

```text
HTTPS endpoint (managed)
 → Cloud Run Service (revision)
 → Container (port 8080 โดย default)
 → Service Account (เรียก GCP API)
 → Secret Manager volume / env
```

ความต่างสำคัญจาก Fargate:

- Scale to zero ได้ง่าย (ประหยัด) แต่มี cold start
- Networking ผ่าน Serverless VPC Access / Direct VPC egress เมื่อต้องคุย private IP
- Traffic splitting ระหว่าง revision = canary แบบ native

### 1.4 เมื่อไหร่เลือกอะไร

| เงื่อนไข                                | แนะนำ                                             |
| --------------------------------------- | ------------------------------------------------- |
| ต้องการ idle = 0 บาท                    | Cloud Run (หรือ Lambda)                           |
| ต้องการ long-running + ALB features ลึก | ECS/Fargate                                       |
| ทีมถนัด Kubernetes อยู่แล้ว             | EKS / GKE                                         |
| งาน CPU สูงต่อเนื่อง 24/7               | คิดค่า Fargate vs GCE/EC2 ให้ดี — อาจถูกกว่าบน VM |

โค้ด: `src/terraform/aws/ecs_fargate.tf`, `src/terraform/gcp/cloud_run.tf`, แอปตัวอย่างใน `src/app/`

---

## 2. Managed Databases

### 2.1 ทำไมไม่ติดตั้ง Postgres บน VM เอง (ในระดับนี้)

Managed DB ให้: automated backup, patch (ตามหน้าต่าง), multi-AZ failover, monitoring metrics พื้นฐาน

คุณยังรับผิดชอบ: schema, query performance, credential rotation, การออกแบบ connection จาก private network

### 2.2 AWS RDS vs GCP Cloud SQL

| หัวข้อ         | AWS RDS                                        | GCP Cloud SQL                   |
| -------------- | ---------------------------------------------- | ------------------------------- |
| Engine         | MySQL, PostgreSQL, MariaDB, SQL Server, Oracle | MySQL, PostgreSQL, SQL Server   |
| HA             | Multi-AZ (synchronous standby)                 | Regional HA (primary + standby) |
| Read scale     | Read Replicas                                  | Read Replicas                   |
| Private access | ใน VPC subnet                                  | Private IP ใน VPC               |
| Auth           | Password, IAM DB auth                          | Password, IAM DB auth           |

### 2.3 แบบอย่าง HA

```text
App (private)
 → writer endpoint → Primary (AZ-a)
 → reader endpoint → Replica (AZ-b) [optional]
  │
  └─ automatic failover (Multi-AZ / Regional HA)
```

**Best practice:**

- วาง DB ใน **private subnet** เท่านั้น
- Security Group / Firewall อนุญาต port 5432/3306 จาก SG ของแอปเท่านั้น ไม่เปิด `0.0.0.0/0`
- เปิด encryption at rest + automated backups
- เก็บ password ใน Secrets Manager / Secret Manager — ไม่ใส่ใน Terraform state ถ้าเลี่ยงได้ (ใช้ random + secret resource อย่างระวัง)

---

## 3. Security & Environment Secrets

### 3.1 ปัญหาที่ต้องเลิกทำ

```bash
# ห้าม
export DB_PASSWORD=SuperSecret123
docker run -e DB_PASSWORD=SuperSecret123 ...
# ห้าม commit
DATABASE_URL=postgres://user:pass@host/db
```

### 3.2 แบบรวมศูนย์

| ความสามารถ          | AWS Secrets Manager               | GCP Secret Manager                    |
| ------------------- | --------------------------------- | ------------------------------------- |
| Versioning          | มี                                | มี                                    |
| Rotation            | Lambda rotation สำเร็จรูป         | หมุนเวียนผ่าน automation ของคุณ / ทูล |
| IAM                 | Resource policy + identity policy | IAM on secret                         |
| Inject เข้า runtime | ECS secrets, Lambda               | Cloud Run secret env/volume           |

### 3.3 รูปแบบที่ปลอดภัยสำหรับ Container

1. สร้าง secret ใน manager
2. ให้ **Task Role / Cloud Run SA** อ่าน secret ได้เท่านั้น
3. Platform inject เป็น env หรือไฟล์ตอน start
4. แอปอ่านจาก env — **ไม่ log ค่า**
5. CI ใช้ OIDC สั้น ๆ ไม่เก็บ long-lived key

ตัวอย่าง: `src/cli/aws/secrets.sh`, `src/cli/gcp/secrets.sh`, `src/env/.env.example`

---

## 4. Virtual Networking (VPC)

### 4.1 ภาพรวมชั้นเครือข่าย

```text
VPC CIDR (เช่น 10.0.0.0/16)
├── Public subnet AZ-a 10.0.0.0/24 ← ALB, NAT, Bastion (ถ้าจำเป็น)
├── Public subnet AZ-b 10.0.1.0/24
├── Private subnet AZ-a 10.0.10.0/24 ← App tasks / VMs
├── Private subnet AZ-b 10.0.11.0/24
├── Data subnet AZ-a 10.0.20.0/24 ← RDS / Cloud SQL
└── Data subnet AZ-b 10.0.21.0/24
```

### 4.2 AWS ศัพท์สำคัญ

| ชิ้นส่วน               | หน้าที่                                                            |
| ---------------------- | ------------------------------------------------------------------ |
| Internet Gateway (IGW) | ออก/เข้า internet จาก public subnet                                |
| NAT Gateway            | ให้ private subnet ออกนอกได้ แต่ไม่รับ inbound จาก internet โดยตรง |
| Route Table            | กำหนดปลายทางของ traffic ตาม subnet                                 |
| Security Group         | Stateful firewall ระดับ ENI (อนุญาตเป็นหลัก)                       |
| Network ACL            | Stateless ระดับ subnet (ใช้เสริม, ระวัง rule ลำดับ)                |

### 4.3 GCP ศัพท์สำคัญ

| ชิ้นส่วน                 | หน้าที่                                                             |
| ------------------------ | ------------------------------------------------------------------- |
| VPC                      | ครอบคลุมหลาย region ใน project ได้                                  |
| Subnet                   | ต่อ region                                                          |
| Cloud Router + Cloud NAT | เทียบเคียง NAT สำหรับ private                                       |
| Firewall Rules           | ใช้ tag / SA เป็น target (ไม่ใช่ SG ต่อ instance แบบ AWS ทุกประการ) |
| Private Google Access    | เข้า Google APIs โดยไม่ต้อง public IP                               |

### 4.4 แบบเทียบ SG vs Firewall

|        | AWS Security Group          | GCP Firewall                    |
| ------ | --------------------------- | ------------------------------- |
| State  | Stateful                    | Stateful สำหรับ allow ทั่วไป    |
| Attach | ต่อ ENI/instance/LB         | กฎในเครือข่าย + target tag/SA   |
| Deny   | Implicit deny (ไม่มี allow) | มี allow/deny ชัดเจน + priority |

โค้ด: `src/terraform/aws/vpc.tf`, `src/terraform/gcp/vpc.tf`

---

## 5. เปรียบเทียบสถาปัตยกรรม AWS vs GCP (ระดับนี้)

### API บน Serverless Container + DB + Secret

**AWS**

```text
Route 53 / ALB
 → ECS Fargate (private)
 → Secrets Manager (DB URL)
 → RDS PostgreSQL Multi-AZ (data subnets)
 VPC endpoints (ถ้าต้องการลด NAT สำหรับ AWS API)
```

**GCP**

```text
Cloud Run (+ HTTPS)
 → Secret Manager
 → Cloud SQL (private IP) ผ่าน connector / Direct VPC
 Cloud NAT สำหรับ egress อื่น ๆ
```

| มุม                  | AWS ได้เปรียบเมื่อ               | GCP ได้เปรียบเมื่อ               |
| -------------------- | -------------------------------- | -------------------------------- |
| เครือข่าย enterprise | SG + NACL + TGW คุ้นในองค์กรใหญ่ | โมเดล firewall + hierarchy โปร่ง |
| Scale to zero        | น้อยกว่า (Fargate มีค่าฐาน)      | Cloud Run เด่น                   |
| DB ops familiarity   | RDS ecosystem กว้าง              | Cloud SQL เรียบง่ายใน DX         |

---

## 6. Best Practices

1. **สามชั้น subnet:** public / app / data — DB ไม่มี public IP
2. **Secrets ผ่าน IAM** ไม่ผ่านไฟล์ใน image
3. **Health check + readiness** ก่อนรับ traffic
4. **Connection pooling** ไปที่ managed DB (PgBouncer / RDS Proxy / AlloyDB connector ตามเคส)
5. **Egress ควบคุม:** NAT มีค่าใช้จ่าย — ใช้ VPC endpoints / Private Google Access เมื่อคุ้ม
6. **อย่าเปิด SSH โล่ง:** ใช้ SSM Session Manager / IAP แทน bastion ค้างคืน
7. **Tag/label + budget alert** ทุก environment

---

## 7. โครงสร้างโค้ด

```text
02-intermediate/
├── README.md
├── LAB.md
├── src/
│ ├── app/   # API เล็ก ๆ สำหรับ deploy บน Fargate/Cloud Run
│ ├── env/.env.example
│ ├── cli/{aws,gcp}/
│ └── terraform/{aws,gcp}/ # VPC + ECS/Cloud Run + DB + Secrets
└── lab/solution/
```

### ลำดับการลงมือ

1. อ่านทฤษฎี VPC และ secrets ให้จบ
2. `terraform apply` เฉพาะ VPC ก่อน ตรวจ route/firewall
3. สร้าง secret แล้วค่อย DB + compute
4. Deploy แอปจาก `src/app`
5. ทำ Lab (scale, broken networking, leaked secret rotation)
