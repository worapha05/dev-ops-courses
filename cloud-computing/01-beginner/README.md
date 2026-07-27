# Level 1 — Beginner: Cloud Paradigms & Compute/Storage Core

ระดับนี้สร้างรากฐานการคิดแบบ Cloud Architect: เข้าใจโมเดลบริการ, ภูมิศาสตร์คลาวด์, Compute, Object Storage และ IAM ก่อนจะไปต่อเรื่อง containers / networking ในระดับถัดไป

---

## สารบัญ

1. [Cloud Fundamentals](#1-cloud-fundamentals)
2. [IaaS vs PaaS vs FaaS](#2-iaas-vs-paas-vs-faas)
3. [เปรียบเทียบสถาปัตยกรรม AWS vs GCP](#3-เปรียบเทียบสถาปัตยกรรม-aws-vs-gcp)
4. [Compute & Virtualization](#4-compute--virtualization)
5. [Cloud Storage Topologies](#5-cloud-storage-topologies)
6. [Cloud IAM Basics](#6-cloud-iam-basics)
7. [Best Practices](#7-best-practices)
8. [โครงสร้างโค้ดในระดับนี้](#8-โครงสร้างโค้ดในระดับนี้)

---

## 1. Cloud Fundamentals

### 1.1 Shared Responsibility Model

คลาวด์ไม่ได้หมายความว่า "ผู้ให้บริการรับผิดชอบทุกอย่าง" แต่เป็นการแบ่งหน้าที่:

| ชั้น                           | ผู้รับผิดชอบโดยทั่วไป                                 | ตัวอย่าง                               |
| ------------------------------ | ----------------------------------------------------- | -------------------------------------- |
| Physical / Datacenter          | Cloud Provider                                        | ไฟฟ้า, ฮาร์ดแวร์, เครือข่ายศูนย์ข้อมูล |
| Hypervisor / Host OS           | Provider (ส่วนใหญ่)                                   | Isolation ของ VM                       |
| Guest OS / Patch               | **ลูกค้า (IaaS)** หรือ Provider (PaaS/FaaS ตามขอบเขต) | update OS บน EC2                       |
| Network config (VPC, firewall) | **ลูกค้า**                                            | Security Group, Firewall Rules         |
| Identity & Access              | **ลูกค้า**                                            | IAM policies, MFA                      |
| Application code & data        | **ลูกค้า**                                            | บั๊กแอป, การเข้ารหัสข้อมูล             |

**AWS vs GCP:** หลักการเหมือนกัน แต่เอกสารเรียกชื่อต่างกัน — AWS ใช้ "Shared Responsibility Model", GCP ใช้ "Shared Responsibility / Shared Fate" (เน้นว่า provider ช่วยออกแบบให้ปลอดภัยร่วมกัน)

จุดที่มักเข้าใจผิด:

- เปิด S3/GCS bucket เป็น public แล้วคิดว่า "AWS/GCP จะกันให้เอง" → **ไม่** นี่คือความรับผิดชอบของลูกค้า
- ใช้ managed DB แล้วไม่ตั้ง backup/encryption → ยังผิด PoLP และ compliance

### 1.2 Regional Architecture

```text
Region (เช่น ap-southeast-1 / asia-southeast1)
 ├── Availability Zone A (datacenter กลุ่มหนึ่ง)
 ├── Availability Zone B
 └── Availability Zone C
```

| แนวคิด                | AWS                                | GCP                           |
| --------------------- | ---------------------------------- | ----------------------------- |
| Region                | `ap-southeast-1` (Singapore)       | `asia-southeast1` (Singapore) |
| Zone                  | AZ: `ap-southeast-1a/b/c`          | Zone: `asia-southeast1-a/b/c` |
| Edge / CDN            | CloudFront                         | Cloud CDN                     |
| Multi-region resource | S3 (เลือก), DynamoDB Global Tables | Multi-region buckets, Spanner |

**ทำไมต้องหลาย AZ?**

- Fault isolation: ไฟดับ/เครือข่ายพังใน zone เดียวไม่ควรทำให้ทั้งระบบล่ม
- High Availability ของ Load Balancer + Auto Scaling กระจายข้าม AZ
- Latency ภายใน region ต่ำกว่า cross-region มาก

**กฎง่าย ๆ สำหรับ Beginner:** เริ่มด้วย **single region, multi-AZ** ก่อน ค่อยคิด multi-region เมื่อมีข้อกำหนด DR/latency จริง

---

## 2. IaaS vs PaaS vs FaaS

| โมเดล    | คุณควบคุมอะไร               | คุณไม่ต้องจัดการ              | ตัวอย่าง AWS                  | ตัวอย่าง GCP                         |
| -------- | --------------------------- | ----------------------------- | ----------------------------- | ------------------------------------ |
| **IaaS** | OS, runtime, scaling config | ฮาร์ดแวร์, hypervisor         | EC2, EBS, VPC                 | Compute Engine, Persistent Disk, VPC |
| **PaaS** | โค้ดแอป, config บางส่วน     | OS patch, หลายส่วนของ runtime | Elastic Beanstalk, App Runner | App Engine, Cloud Run (บางมุม)       |
| **FaaS** | function + trigger          | Server, scaling เกือบทั้งหมด  | Lambda                        | Cloud Functions                      |

### เมื่อไหร่เลือกอะไร

| สถานการณ์                                     | แนะนำ                                     |
| --------------------------------------------- | ----------------------------------------- |
| ต้องการควบคุม kernel / ติดตั้ง agent พิเศษ    | IaaS (EC2 / GCE)                          |
| Deploy container โดยไม่ยุ่งกับ node           | Fargate / Cloud Run (ใกล้ PaaS+container) |
| Event-driven งานสั้น (รูปภาพ resize, webhook) | FaaS                                      |
| Legacy app ที่ต้อง SSH และ patch เอง          | IaaS ก่อน แล้วค่อย migrate                |

**Trade-off สำคัญ:** ยิ่ง abstraction สูง (PaaS/FaaS) ยิ่งลดงาน ops แต่เสียความยืดหยุ่นและอาจเจอ vendor lock-in / cold start / timeout

---

## 3. เปรียบเทียบสถาปัตยกรรม AWS vs GCP

### 3.1 ปรัชญาการออกแบบ

| มิติ            | AWS                               | GCP                                              |
| --------------- | --------------------------------- | ------------------------------------------------ |
| วิวัฒนาการ      | บริการเยอะมาก แยกย่อยตาม use case | บริการกระชับ ชื่อสอดคล้องกัน                     |
| Networking      | VPC + Subnet ต่อ AZ + SG/NACL     | VPC แบบ global-ish ใน project, subnet ต่อ region |
| Identity        | Account-centric (IAM ใน account)  | Project/Folder/Org hierarchy                     |
| Default mindset | "เลือก building block แล้วประกอบ" | "managed service ก่อน แล้วค่อยลง IaaS"           |

### 3.2 Compute เทียบกัน

| ความสามารถ    | AWS EC2                                  | GCP Compute Engine                       |
| ------------- | ---------------------------------------- | ---------------------------------------- |
| Instance type | ตระกูล t/m/c/r/g…                        | E2/N2/C2/… machine families              |
| Spot          | Spot Instances                           | Spot / Preemptible VMs                   |
| Metadata      | Instance Metadata Service (IMDSv2 แนะนำ) | Metadata server                          |
| Image         | AMI                                      | Images / Machine Images                  |
| Autoscale     | Auto Scaling Group (ASG)                 | Managed Instance Group (MIG)             |
| LB            | ALB / NLB / CLB                          | External/Internal HTTP(S) LB, TCP/UDP LB |

### 3.3 Storage เทียบกัน

| ความสามารถ          | AWS S3                        | GCP Cloud Storage                     |
| ------------------- | ----------------------------- | ------------------------------------- |
| Unit                | Bucket + Object               | Bucket + Object                       |
| Consistency         | Strong read-after-write       | Strong consistency                    |
| Classes             | Standard, IA, Glacier…        | Standard, Nearline, Coldline, Archive |
| Public access block | Block Public Access (ควรเปิด) | Uniform bucket-level access + IAM     |
| Static website      | รองรับ (ระวัง public)         | รองรับผ่าน backend bucket / CDN       |

### 3.4 IAM เทียบกัน

| แนวคิด            | AWS                            | GCP                                    |
| ----------------- | ------------------------------ | -------------------------------------- |
| Principal         | User, Role, Federated          | User, Service Account, Group           |
| Permission bundle | Managed / Inline Policy        | Role (primitive / predefined / custom) |
| Temporary creds   | STS AssumeRole                 | Short-lived SA keys / WIF              |
| Org structure     | Organizations + OUs + Accounts | Organization → Folders → Projects      |

---

## 4. Compute & Virtualization

### 4.1 Virtual Machine บน AWS (EC2)

องค์ประกอบหลักที่ต้องออกแบบทุกครั้ง:

1. **AMI** — OS + bootstrap
2. **Instance type** — CPU/RAM/network
3. **Subnet** — public (มี public IP/IGW) หรือ private
4. **Security Group** — stateful firewall ระดับ instance
5. **IAM Instance Profile** — สิทธิ์ที่ instance เรียก AWS API ได้ (อย่าฝัง access key)
6. **User data / cloud-init** — script เริ่มต้น

### 4.2 Virtual Machine บน GCP (Compute Engine)

คล้าย EC2 แต่ใช้:

- **Network tags** + **Firewall rules** แทน Security Groups (แนวคิดใกล้กันแต่โมเดลต่าง)
- **Service Account** ผูกกับ VM (เทียบได้กับ Instance Profile)
- **MIG + Autoscaler** แทน ASG

### 4.3 Auto Scaling + Load Balancer

```text
Internet
 │
 ▼
Load Balancer (multi-AZ)
 │
 ├─► VM / Task in AZ-a
 ├─► VM / Task in AZ-b
 └─► VM / Task in AZ-c
  ▲
  │
 Auto Scaling (CPU / request / custom metric)
```

**Best practice เริ่มต้น:**

- Health check ที่แอปจริง (`/healthz`) ไม่ใช่แค่ ICMP
- Scale บน metric ที่สะท้อน user experience (latency, queue depth) ไม่ใช่แค่ CPU
- Connection draining / graceful shutdown ก่อน terminate

โค้ดตัวอย่าง: `src/terraform/aws/` และ `src/terraform/gcp/` รวมถึง CLI ใน `src/cli/`

---

## 5. Cloud Storage Topologies

### 5.1 Object Storage คืออะไร

เหมาะกับไฟล์ที่ไม่ต้อง POSIX (รูป, backup, static assets, data lake)
ไม่ใช่ไฟล์ระบบของแอปที่ต้องการ lock/rename บ่อย ๆ แบบ NFS

### 5.2 Lifecycle Policies

ตัวอย่างนโยบายต้นทุน:

| อายุวัตถุ                  | Action แนะนำ                    |
| -------------------------- | ------------------------------- |
| 0–30 วัน                   | Standard                        |
| 30–90 วัน                  | Infrequent / Nearline           |
| 90+ วัน                    | Glacier / Coldline หรือ Archive |
| มี version เก่าเกิน N รุ่น | ลบ noncurrent versions          |

### 5.3 Bucket Permissions & Static Hosting

**อันตราย classic:** เปิด `public-read` ทั้ง bucket เพื่อ host เว็บ
แนวทางที่ปลอดภัยกว่า:

1. ปิด public access ที่ bucket
2. ใส่ CloudFront / Cloud CDN หน้า
3. อนุญาต origin ผ่าน OAI/OAC (AWS) หรือ signed URL / backend bucket IAM (GCP)
4. เปิด versioning + encryption

script ตัวอย่าง: `src/cli/aws/setup-s3-static.sh`, `src/cli/gcp/setup-gcs-bucket.sh`

---

## 6. Cloud IAM Basics

### 6.1 Principle of Least Privilege (PoLP)

> ให้สิทธิ์ **แคบที่สุด** ที่ยังทำงานได้ และ **สั้นที่สุด** ตามเวลาที่จำเป็น

Checklist:

- [ ] แยก human user กับ machine identity (service account / role)
- [ ] ไม่ใช้ root / Owner ในงานประจำวัน
- [ ] เปิด MFA สำหรับมนุษย์
- [ ] ใช้ groups/roles รวมสิทธิ์ แทนการติด policy ทีละคน
- [ ] ห้าม commit access keys / JSON key ลง Git

### 6.2 AWS: Users, Groups, Roles

| ประเภท   | ใช้เมื่อ                                                   |
| -------- | ---------------------------------------------------------- |
| IAM User | มนุษย์ (หรือระบบเก่า) — แนะนำย้ายไป Identity Center/SSO    |
| Group    | รวมสิทธิ์มนุษย์ตามทีม                                      |
| Role     | workload / cross-account / federation — **แนะนำสำหรับแอป** |

### 6.3 GCP: Users, Groups, Service Accounts

| ประเภท                           | ใช้เมื่อ                                    |
| -------------------------------- | ------------------------------------------- |
| Google Account / Workspace Group | มนุษย์                                      |
| Service Account                  | แอป, CI, VM                                 |
| Custom Role                      | ตัดสิทธิ์จาก predefined role ที่กว้างเกินไป |

ตัวอย่าง CLI: `src/cli/aws/iam-bootstrap.sh`, `src/cli/gcp/iam-bootstrap.sh`

---

## 7. Best Practices

### ความปลอดภัย

1. เปิด **S3 Block Public Access** / GCS **Uniform bucket-level access**
2. ใช้ **IMDSv2** บน EC2 และจำกัด SA scopes บน GCE
3. เข้ารหัสดิสก์และ object ด้วย CMK/CMEK เมื่อมีข้อกำหนด compliance
4. แยกบัญชี/project: `dev` / `staging` / `prod`

### ความทนทาน (Reliability)

1. Deploy compute อย่างน้อย 2 AZ
2. Backup สำคัญ + ทดสอบ restore (backup ที่ไม่เคย restore = ยังไม่ใช่ backup)
3. Tag/label ทุก resource: `env`, `owner`, `cost-center`

### ต้นทุน (Cost)

1. ใช้ Free Tier / budget alert ตั้งวันที่ 1
2. ปิด/ทำลาย lab resources หลังเลิกใช้
3. เลือก instance เล็กสุดที่ยังผ่าน health check แล้วค่อย scale out

### Operations

1. Infrastructure ที่สำคัญควรเป็นโค้ด (เริ่มจาก Terraform ในระดับนี้ แล้วลึกขึ้นใน Expert)
2. เก็บ state/credentials นอก Git
3. บันทึก runbook: สร้าง / ตรวจ / ทำลาย

---

## 8. โครงสร้างโค้ดในระดับนี้

```text
01-beginner/
├── README.md   ← คุณอยู่ที่นี่
├── LAB.md   ← โจทย์ + เฉลยแนวคิด
├── src/
│ ├── env/
│ │ └── .env.example ← template ตัวแปรปลอดภัย
│ ├── cli/
│ │ ├── aws/  ← aws cli scripts
│ │ └── gcp/  ← gcloud scripts
│ └── terraform/
│ ├── aws/  ← EC2 + S3 + IAM ตัวอย่าง
│ └── gcp/  ← GCE + GCS + IAM ตัวอย่าง
└── lab/solution/  ← เฉลยไฟล์สำหรับ Lab
```

### ลำดับการลงมือ

1. คัดลอก `src/env/.env.example` → `.env` (อย่า commit)
2. รัน CLI bootstrap IAM + storage
3. `terraform init/plan/apply` ใน folder cloud ที่เลือก
4. ทำ Lab ใน `LAB.md`
5. `terraform destroy` + script cleanup

---

## เกณฑ์ผ่านระดับ Beginner

คุณพร้อมไป Intermediate เมื่ออธิบายได้ว่า:

- Shared Responsibility ของ S3 bucket ที่ตั้งผิด public ตกอยู่กับใคร
- ทำไม ASG/MIG ต้องอยู่หลัง Load Balancer หลาย AZ
- ต่างกันอย่างไรระหว่าง IAM User กับ Role / Service Account
- จะ host static website โดยไม่เปิด bucket ทั้งใบเป็น public ได้อย่างไร
