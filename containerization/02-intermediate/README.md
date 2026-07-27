# Level 2 — Intermediate: Production-Ready Docker & Kubernetes Essentials

เป้าหมายระดับนี้: ยกระดับจาก “รันได้บนเครื่อง” เป็น **image ที่พร้อมขึ้น cloud** และเริ่มใช้ **Kubernetes**
เจาะ **Multi-stage Builds**, สถาปัตยกรรม Control Plane / Worker, object พื้นฐาน และ **Service networking**

---

## สารบัญ

1. [Production Dockerfiles & Multi-stage Builds](#1-production-dockerfiles--multi-stage-builds)
2. [ความปลอดภัยและความเล็กของ Image](#2-ความปลอดภัยและความเล็กของ-image)
3. [Introduction to Kubernetes](#3-introduction-to-kubernetes)
4. [object พื้นฐาน: Pod, ReplicaSet, Deployment](#4-object พื้นฐาน-pod-replicaset-deployment)
5. [Local Cluster — Minikube / Kind + kubectl](#5-local-cluster--minikube--kind--kubectl)
6. [Service & Networking](#6-service--networking)
7. [หลักออกแบบ Infrastructure ระดับ Intermediate](#7-หลักออกแบบ-infrastructure-ระดับ-intermediate)
8. [Best Practices สรุป](#8-best-practices-สรุป)

---

## 1. Production Dockerfiles & Multi-stage Builds

### ปัญหาของ Dockerfile ชั้นเดียว

```dockerfile
FROM node:20 # มี compiler, npm cache, shell tools
COPY . .
RUN npm install # อาจติด devDependencies
CMD ["node", "app.js"]
```

ผลลัพธ์ที่พบบ่อย:

- Image ใหญ่เกินจำเป็น → pull ช้า, attack surface กว้าง
- เครื่องมือ build หลงไป production
- Source / secret ช่วง build อาจติด layer

### Multi-stage คืออะไร

ใช้หลาย `FROM` ในไฟล์เดียว — **stage แรก build**, **stage สุดท้ายเหลือของที่ต้องรัน**

```dockerfile
# ----- build stage -----
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build && npm prune --omit=dev

# ----- runtime stage -----
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./
USER node
EXPOSE 8080
CMD ["node", "dist/server.js"]
```

| Stage  | มีอะไร                         | ไม่มีอะไร                    |
| ------ | ------------------------------ | ---------------------------- |
| build  | compiler, devDeps, source เต็ม | —                            |
| runner | artifacts + prod deps          | git, test tools, build cache |

> เหมาะกับ **Google Cloud Run**, ECS, Kubernetes — ที่คิดเงินตามขนาด image / cold start / security scanning

ตัวอย่าง: [`examples/01-multistage-dockerfile/`](./examples/01-multistage-dockerfile/)

### เทคนิคเพิ่มสำหรับ Cloud Run / container platforms

| เทคนิค                                  | เหตุผล                               |
| --------------------------------------- | ------------------------------------ |
| Listen `0.0.0.0` และอ่าน `PORT` จาก env | platform inject port เอง             |
| Stateless process                       | scale แนวนอนได้โดยไม่พึ่ง local disk |
| Health endpoint เบา                     | platform ใช้ทำ readiness             |
| Distroless / alpine / chainguard        | ลด CVE จาก OS package                |
| ไม่ใช้ root                             | policy หลายที่บังคับ non-root        |

---

## 2. ความปลอดภัยและความเล็กของ Image

### Checklist ก่อนขึ้น registry

1. Base image มี tag ชัด + digest เมื่อ lock ได้
2. ไม่มี `.env`, private key ใน build context (ใช้ `.dockerignore`)
3. `USER` ไม่ใช่ root
4. ติดตั้งเฉพาะ dependency ที่รันจริง
5. สแกนด้วย Trivy / Grype ใน CI (เชื่อมกับหลักสูตร CI/CD ได้)

ตัวอย่าง `.dockerignore`:

```gitignore
node_modules
.git
.env
*.md
coverage
```

### เปรียบเทียบขนาด (แนวคิด)

```
node:20   ~1GB+
node:20-alpine  ~200MB
multi-stage alpine เล็กลงอีก เพราะตัด build tools
distroless/static เล็กมาก แต่ debug ยากกว่า
```

---

## 3. Introduction to Kubernetes

**Kubernetes** คือระบบ **orchestrate container** บน cluster หลายเครื่อง
คุณประกาศ **desired state** (อยากได้ Deployment 3 replicas) แล้ว control loop จะปรับจริงให้ตรง

### ทำไมต้องมีหลัง Docker Compose

| Docker Compose                | Kubernetes                          |
| ----------------------------- | ----------------------------------- |
| เครื่องเดียว / local เป็นหลัก | หลายโหนด, self-heal, rolling update |
| ไฟล์ compose เป็นศูนย์กลาง    | API objects + controllers           |
| Restart นโยบายจำกัด           | ReplicaSet, HPA, PDB ระดับ cluster  |

Compose ยังเหมาะกับ **local dev** — K8s เหมาะกับ **รันและดูแลในระยะยาว**

### สถาปัตยกรรม: Control Plane vs Worker Nodes

```
┌────────────── Control Plane ──────────────┐
│ API Server ← จุดเข้าทุกคำสั่ง kubectl │
│ etcd ← เก็บ state ของ cluster │
│ Scheduler ← เลือก node ให้ Pod  │
│ Controllers ← Deployment/ReplicaSet/… │
└───────────────────────────────────────────┘
   │
 ┌──────────────┼──────────────┐
 ▼  ▼  ▼
 Worker Node Worker Node Worker Node
 kubelet kubelet kubelet
 kube-proxy kube-proxy kube-proxy
 container runtime + Pods
```

| ส่วน                   | หน้าที่                                            |
| ---------------------- | -------------------------------------------------- |
| **API Server**         | รับ YAML/JSON, authn/authz, เป็น front ของ cluster |
| **etcd**               | key-value store ของ desired/actual state           |
| **Scheduler**          | วาง Pod ลง Node ตาม resource/affinity              |
| **Controller Manager** | reconcile (เช่น สร้าง Pod ใหม่เมื่อตาย)            |
| **kubelet**            | agent บน Node คุยกับ API แล้วรัน Pod               |
| **kube-proxy**         | ช่วยทำ Service networking (หรือโหมดเทียบเท่า)      |

ตัวอย่างแผนภาพเพิ่ม: [`examples/02-k8s-architecture/`](./examples/02-k8s-architecture/)

---

## 4. object พื้นฐาน: Pod, ReplicaSet, Deployment

### Pod

หน่วยเล็กสุดที่ schedule ได้ — หนึ่ง Pod มีได้หนึ่งหรือหลาย container ที่แชร์ network namespace และ volumes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello
spec:
  containers:
    - name: web
  image: nginx:1.27-alpine
  ports:
    - containerPort: 80
```

> ในงานจริงแทบไม่สร้าง Pod เปล่า ๆ ระยะยาว — ใช้ **Deployment** ครอบ

### ReplicaSet

ดูแลให้มีจำนวน Pod ตาม `replicas`
ถูกละไว้ใต้ Deployment เป็นส่วนใหญ่

### Deployment

object ที่ใช้ update แอปแบบประกาศ:

- กำหนดจำนวน replica
- Rolling update / rollback
- ผูก label selector กับ Pod template

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
 name: backend
spec:
 replicas: 3
 selector:
 matchLabels:
 app: backend
 template:
 metadata:
 labels:
 app: backend
 spec:
 containers:
 - name: backend
  image: ghcr.io/example/backend:1.2.0
  ports:
  - containerPort: 3000
```

```
kubectl apply -f deployment.yaml
kubectl rollout status deployment/backend
kubectl rollout undo deployment/backend
```

---

## 5. Local Cluster — Minikube / Kind + kubectl

### ตัวเลือก

| เครื่องมือ   | จุดเด่น                               | เหมาะกับ              |
| ------------ | ------------------------------------- | --------------------- |
| **Minikube** | UX ดี, addons (ingress, metrics) ง่าย | เรียนมือใหม่          |
| **Kind**     | รันด้วย Docker containers เป็น nodes  | CI, ทดสอบหลายโหนดเร็ว |

### kubectl พื้นฐาน

```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
kubectl apply -f manifest.yaml
kubectl describe pod <name>
kubectl logs deploy/backend
kubectl exec -it deploy/backend -- sh
kubectl delete -f manifest.yaml
```

### เริ่ม Minikube / Kind

```bash
# Minikube
minikube start
kubectl get nodes
minikube addons enable metrics-server # สำหรับ HPA ภายหลัง

# Kind
kind create cluster --name bootcamp
kubectl cluster-info --context kind-bootcamp
```

ตัวอย่าง script: [`examples/03-local-cluster/`](./examples/03-local-cluster/)

> บน WSL2 ตรวจว่า Docker ใช้งานได้ก่อนสตาร์ท cluster

---

## 6. Service & Networking

Pod ได้ IP ชั่วคราว — เมื่อ recreate IP เปลี่ยน
**Service** ให้ **DNS ชื่อคงที่** และ load balance ไปยัง Pod ที่ match label

### ประเภท Service ที่ต้องรู้

| Type                    | พฤติกรรม                           | ใช้เมื่อ                                                                   |
| ----------------------- | ---------------------------------- | -------------------------------------------------------------------------- |
| **ClusterIP** (default) | IP ภายใน cluster เท่านั้น          | backend, database client ภายใน                                             |
| **NodePort**            | เปิด port บนทุก Node (30000–32767) | ทดสอบภายนอกแบบเร็ว                                                         |
| **LoadBalancer**        | ขอ LB จาก cloud provider           | production บน cloud; local อาจเป็น pending หรือใช้ metallb/minikube tunnel |

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  type: ClusterIP
  selector:
  app: backend
  ports:
    - port: 80
  targetPort: 3000
```

ภายใน cluster เรียก: `http://backend` หรือ `http://backend.default.svc.cluster.local`

### แผนภาพ traffic

```
Client
 │
 ▼
Service (virtual IP / DNS)
 │
 ├── Pod backend-a
 ├── Pod backend-b
 └── Pod backend-c
```

ตัวอย่างครบ: [`examples/04-services-networking/`](./examples/04-services-networking/)

### Minikube เข้าถึง Service

```bash
kubectl expose deploy/backend --type=NodePort --port=80 --target-port=3000
minikube service backend --url
# หรือ
minikube tunnel # สำหรับ LoadBalancer
```

> **คำใบ้ (Docker driver):** บน Linux/WSL ที่ Minikube ใช้ `--driver=docker` คำสั่ง `minikube service --url` มัก**ค้าง** เพราะต้องเปิด tunnel
> แนะนำให้ใช้ `kubectl port-forward` แทน:
>
> ```bash
> kubectl port-forward svc/backend 8080:80
> # แล้วเปิด http://127.0.0.1:8080/
> ```

---

## 7. หลักออกแบบ Infrastructure ระดับ Intermediate

| หลัก                                 | ปฏิบัติ                                                             |
| ------------------------------------ | ------------------------------------------------------------------- |
| Desired state ใน Git                 | Manifest อยู่ใน repo — apply ซ้ำได้                                 |
| Label อย่างมีวินัย                   | `app`, `tier`, `version` ใช้กับ selector                            |
| แยก build กับ runtime                | multi-stage + image tag จาก commit SHA                              |
| หนึ่ง Deployment หนึ่งหน้าที่        | อย่ายัด sidecar ไม่จำเป็นใน Pod เดียวถ้ายังไม่เข้าใจ                |
| Service หน้าทุก workload ที่ถูกเรียก | อย่าชี้ Pod IP ตรง ๆ                                                |
| Local ≠ Production                   | Minikube ใช้เรียน — production ต้องคิด IAM, network policy, ingress |

วงจรแนะนำ:

```
เขียน Dockerfile (multi-stage)
 → build & tag
 → โหลดเข้า Minikube/Kind (หรือ push registry)
 → Deployment + Service YAML
 → kubectl apply
 → ตรวจ logs / endpoints
```

---

## 8. Best Practices สรุป

1. **Multi-stage** เป็นค่าเริ่มต้นสำหรับ image ที่จะขึ้น shared environment
2. ใช้ **`.dockerignore`** และ non-root user
3. เรียนรู้โมเดล **Control Plane / Worker** ก่อนท่องจำ YAML
4. ใช้ **Deployment** ไม่สร้าง Pod ค้างมือ
5. เปิดแอปด้วย **Service** ที่ type เหมาะกับขั้น (ClusterIP → NodePort/LB)
6. ตั้งชื่อและ label ให้ค้นและ select ได้
7. `kubectl describe` + `logs` คือเพื่อนคู่ใจตอน Pod ไม่ Ready
8. เก็บ manifest ใน Git — อย่าแก้ของใน cluster แล้วลืม

---

## ไฟล์ตัวอย่างในระดับนี้

| folder                                                                       | เนื้อหา                       |
| ---------------------------------------------------------------------------- | ----------------------------- |
| [`examples/01-multistage-dockerfile/`](./examples/01-multistage-dockerfile/) | Multi-stage Node API          |
| [`examples/02-k8s-architecture/`](./examples/02-k8s-architecture/)           | แผนภาพและ glossary            |
| [`examples/03-local-cluster/`](./examples/03-local-cluster/)                 | script Minikube / Kind        |
| [`examples/04-services-networking/`](./examples/04-services-networking/)     | Deployment + Service หลายชนิด |

เมื่อพร้อมแล้วไปที่ [`LAB.md`](./LAB.md) — สถานการณ์ย้าย **ParcelGo API** ขึ้น cluster ท้องถิ่น
