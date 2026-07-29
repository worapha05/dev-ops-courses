📍 **Nav:** [`🏠 Dev Learning Courses Hub`](https://github.com/worapha05/dev-learning-courses-hub/blob/main/README.md) | [`📂 DevOps Courses Index`](../README.md) | 📝 [`Prompt File`](https://github.com/worapha05/ai-learning-prompts-hub/blob/main/course-generation/dev-ops-courses/containerization-prompt.md)

---

# Containerization Bootcamp — Zero to Expert

bootcamp เรียนรู้ **Containerization** แบบครบวงจร เน้น **Docker และ Kubernetes (K8s)**
จาก Foundations / Local Operations → Production Docker / K8s Essentials → Enterprise Orchestration & Resilience

---

## เป้าหมายของหลักสูตร

เมื่อจบหลักสูตรนี้ คุณจะสามารถ:

- อธิบายความต่างของ **Container กับ VM** และองค์ประกอบ Image / Container / Registry
- ใช้ **Docker CLI** จัดการ lifecycle ของ container และออกแบบ **Volumes / Networks** ให้ถูกต้อง
- เขียน **Dockerfile** และ **docker-compose.yml** เพื่อรันแอป Full-stack ในเครื่องท้องถิ่น
- สร้าง **Multi-stage Dockerfile** ที่เล็ก ปลอดภัย และเหมาะกับ platform อย่าง Cloud Run
- เข้าใจสถาปัตยกรรม Kubernetes และจัดการ **Pod / Deployment / Service** ด้วย `kubectl`
- ออกแบบระบบระดับ production: **ConfigMap/Secret, HPA, Probes, Ingress, PV/PVC, NetworkPolicy**

---

## โครงสร้างหลักสูตร

| Level            | folder                                   | หัวข้อหลัก                                                    | เวลาแนะนำ   |
| ---------------- | ---------------------------------------- | ------------------------------------------------------------- | ----------- |
| 1 — Beginner     | [`01-beginner/`](./01-beginner/)         | Container concepts, Docker CLI, Volumes/Networks, Compose     | 1–2 สัปดาห์ |
| 2 — Intermediate | [`02-intermediate/`](./02-intermediate/) | Multi-stage builds, K8s architecture, Minikube/Kind, Services | 2–3 สัปดาห์ |
| 3 — Expert       | [`03-expert/`](./03-expert/)             | Config/Secrets, HPA & Probes, Ingress, Storage, Security      | 2–4 สัปดาห์ |

แต่ละระดับประกอบด้วย:

1. **`README.md`** — ทฤษฎีเชิงลึกภาษาไทย เน้นสถาปัตยกรรมและหลักออกแบบ Infrastructure
2. **`examples/`** — Dockerfile / Compose / Kubernetes Manifests ที่ใช้เป็นตัวอย่างได้จริง
3. **`LAB.md`** — โจทย์สถานการณ์จริงพร้อมเฉลยเต็มใน `lab/solution/`

---

## ข้อกำหนดเบื้องต้น

- ความรู้พื้นฐาน Linux shell และ Git
- ความเข้าใจพื้นฐาน HTTP และแอปเว็บ (frontend / backend / database)
- ติดตั้ง [Docker](https://www.docker.com/) และ [Docker Compose](https://docs.docker.com/compose/)
- สำหรับ Intermediate+: [kubectl](https://kubernetes.io/docs/tasks/tools/), [Minikube](https://minikube.sigs.k8s.io/) หรือ [Kind](https://kind.sigs.k8s.io/)

```bash
docker --version
docker compose version
kubectl version --client
# อย่างใดอย่างหนึ่ง
minikube version
# หรือ
kind version
```

---

## วิธีใช้ Bootcamp

1. อ่าน `README.md` ของระดับนั้นให้จบ — โฟกัสที่ **ทำไมออกแบบแบบนี้** ไม่ใช่แค่คำสั่ง
2. เปิด `examples/` แล้วทดลองทีละ folder
3. ทำ Lab ใน `LAB.md` **ด้วยตัวเองก่อน** แล้วค่อยดูเฉลย
4. ไประดับถัดไปเมื่ออธิบาย trade-off ของ design ได้

```bash
cd containerization-bootcamp

# ทดลอง sample app แบบ local (Beginner Compose)
cd 01-beginner/sample-app
docker compose up --build
```

| บริการ           | Host Port | Notes                         |
| ---------------- | --------- | ----------------------------- |
| Frontend (nginx) | `8080`    | Static UI เรียก Backend       |
| Backend (Node)   | `3000`    | REST API                      |
| PostgreSQL       | `5432`    | ข้อมูล persistent ผ่าน volume |

---

## Roadmap แนะนำ

```
Week 1–2 Beginner: docker run → volumes/networks → compose full-stack
Week 3–5 Intermediate: multi-stage image → Minikube/Kind → Deployment + Service
Week 6–9 Expert: Config/Secret → Probes/HPA → Ingress/TLS → PV/PVC → NetworkPolicy
```

---

## หลักการออกแบบที่ใช้ตลอดทั้งหลักสูตร

| หลัก                      | ความหมายปฏิบัติ                                                           |
| ------------------------- | ------------------------------------------------------------------------- |
| Immutable artifacts       | Image ที่ deploy ต้องระบุด้วย digest/tag ที่ย้อนกลับได้ ไม่พึ่ง `:latest` |
| Least privilege           | Process ใน container รัน non-root, Secret ไม่ hardcode ใน image           |
| Declarative desired state | K8s Manifest บอก “อยากได้อะไร” ไม่ใช่ “รันคำสั่งอะไรทีละขั้น”             |
| Fail fast & health        | Probe + readiness ทำให้ traffic ไม่เข้า instance ที่ยังไม่พร้อม           |
| Data vs compute           | แยก stateful (volume/PVC) ออกจาก ephemeral container filesystem           |

---

## link ด่วน

- [Beginner README](./01-beginner/README.md) · [Lab](./01-beginner/LAB.md)
- [Intermediate README](./02-intermediate/README.md) · [Lab](./02-intermediate/LAB.md)
- [Expert README](./03-expert/README.md) · [Lab](./03-expert/LAB.md)
- [Sample App](./01-beginner/sample-app/)
