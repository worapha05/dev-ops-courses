📍 **Nav:** [`🏠 Dev Learning Courses Hub`](https://github.com/worapha05/dev-learning-courses-hub/blob/main/README.md) | [`📂 DevOps Courses Index`](../README.md) | 📝 [`Prompt File`](https://github.com/worapha05/ai-learning-prompts-hub/blob/main/course-generation/dev-ops-courses/ci-cd-pipeline-prompt.md)

---

# CI/CD Pipeline Bootcamp — Zero to Expert

bootcamp เรียนรู้ **CI/CD Pipelines** แบบครบวงจร เน้น **GitHub Actions และ Jenkins**
จาก Foundations / Basic Workflows → Pipeline as Code / Security → Enterprise Delivery / Cloud Deploy

---

## เป้าหมายของหลักสูตร

เมื่อจบหลักสูตรนี้ คุณจะสามารถ:

- อธิบายความต่างของ **Continuous Integration (CI)** กับ **Continuous Delivery / Deployment (CD)** และออกแบบ workflow ที่เหมาะสม
- เขียน **GitHub Actions** (Workflows, Jobs, Steps, Triggers, Secrets, Matrix) ได้จริง
- ติดตั้ง **Jenkins ด้วย Docker**, สร้าง Freestyle Job และเขียน **Declarative Jenkinsfile**
- จัดการ **Secrets / Credentials** อย่างปลอดภัย และเก็บ **Artifacts** จาก build
- สร้าง pipeline ระดับ production: **Build Docker → Push Registry → Deploy Cloud** พร้อม Blue-Green / Canary / Approval
- เร่งความเร็วด้วย **dependency caching** และเพิ่มความปลอดภัยด้วย **SAST (Trivy / SonarQube)**

---

## โครงสร้างหลักสูตร

| Level            | folder                                   | หัวข้อหลัก                                                        | เวลาแนะนำ   |
| ---------------- | ---------------------------------------- | ----------------------------------------------------------------- | ----------- |
| 1 — Beginner     | [`01-beginner/`](./01-beginner/)         | CI/CD concepts, GitHub Actions basics, Jenkins Docker + Freestyle | 1–2 สัปดาห์ |
| 2 — Intermediate | [`02-intermediate/`](./02-intermediate/) | Jenkinsfile Declarative, Secrets, Tests & Artifacts, Matrix       | 2–3 สัปดาห์ |
| 3 — Expert       | [`03-expert/`](./03-expert/)             | Docker/Registry/Cloud Deploy, Blue-Green/Canary, Cache & SAST     | 2–4 สัปดาห์ |

แต่ละระดับประกอบด้วย:

1. **`README.md`** — ทฤษฎีเชิงลึกภาษาไทย เน้น Automation Pipeline และการออกแบบ Workflow
2. **`examples/`** — ไฟล์ YAML / Jenkinsfile / Docker ที่ใช้เป็นตัวอย่างได้จริง
3. **`LAB.md`** — โจทย์สถานการณ์จริงพร้อมเฉลยเต็มใน `lab/solution/`

---

## ข้อกำหนดเบื้องต้น

- ความรู้พื้นฐาน Git (branch, commit, push, pull request)
- ความเข้าใจพื้นฐาน Linux shell และ Docker
- บัญชี [GitHub](https://github.com/) (สำหรับ Actions)
- ติดตั้ง [Docker](https://www.docker.com/) และ [Docker Compose](https://docs.docker.com/compose/)

```bash
docker --version
docker compose version
git --version
```

---

## วิธีใช้ Bootcamp

1. อ่าน `README.md` ของระดับนั้นให้จบ — โฟกัสที่ **ทำไมออกแบบ pipeline แบบนี้**
2. เปิด `examples/` แล้วอ่าน/ทดลอง workflow ทีละไฟล์
3. ทำ Lab ใน `LAB.md` **ด้วยตัวเองก่อน** แล้วค่อยดูเฉลย
4. ไประดับถัดไปเมื่ออธิบาย trade-off ของ pipeline design ได้

```bash
cd cicd-pipeline-bootcamp

# สตาร์ท Jenkins (Beginner+)
docker compose -f 01-beginner/examples/04-jenkins-docker-setup/docker-compose.yml up -d

# ดู initial admin password
docker compose -f 01-beginner/examples/04-jenkins-docker-setup/docker-compose.yml exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# ทดลอง sample app (ใช้ในหลาย lab)
cd 01-beginner/sample-app
npm install
npm test
```

| บริการ                  | Host Port | Notes                              |
| ----------------------- | --------- | ---------------------------------- |
| Jenkins                 | `8080`    | Web UI — รหัสเริ่มต้นจาก container |
| Jenkins Agent (inbound) | `50000`   | สำหรับ connected agents            |

---

## Learning Path ที่แนะนำ

```
Beginner: CI/CD mindset + GitHub Actions syntax + Jenkins Freestyle
 ↓
Intermediate: Jenkinsfile + Secrets + Tests/Artifacts + Matrix
 ↓
Expert: Docker/Registry/Cloud + Blue-Green/Canary + Cache/SAST
 ↓
project จริงของคุณเอง (Deploy API/Frontend ด้วย pipeline อัตโนมัติ)
```

---

## หลักการสำคัญที่หลักสูตรย้ำตลอด

| หลักการ             | ความหมายใน CI/CD                                                       |
| ------------------- | ---------------------------------------------------------------------- |
| Pipeline as Code    | เก็บ workflow ใน Git — review ได้, rollback ได้, ไม่พึ่ง UI อย่างเดียว |
| Fail fast           | รัน lint/test ก่อน build/deploy ที่แพง                                 |
| Secrets ไม่ขึ้น Git | ใช้ GitHub Secrets / Jenkins Credentials เท่านั้น                      |
| Idempotent deploy   | รันซ้ำได้ผลเหมือนเดิม — ไม่พึ่งขั้นตอนมือในเครื่องใครคนหนึ่ง           |
| Observability       | log, artifact, status check ต้องอ่านรู้ว่า fail ที่ไหน                 |
| Least privilege     | token/role ของ pipeline ได้สิทธิ์เท่าที่จำเป็น                         |

---

## Tech Stack มาตรฐานของหลักสูตร

| ชั้น                  | เทคโนโลยี                                        |
| --------------------- | ------------------------------------------------ |
| CI (cloud-native)     | GitHub Actions                                   |
| CI/CD (self-hosted)   | Jenkins LTS (Docker)                             |
| Language (ตัวอย่าง)   | Node.js 20+                                      |
| Container             | Docker / multi-stage Dockerfile                  |
| Registry              | Docker Hub / GitHub Container Registry (ghcr.io) |
| Cloud deploy (Expert) | Google Cloud Run / AWS (ตัวอย่าง workflow)       |
| Security scan         | Trivy, SonarQube (แนวคิด + ตัวอย่าง)             |
