# Level 3 — Expert: Enterprise Kubernetes Orchestration & Resilience

เป้าหมายระดับนี้: ออกแบบ cluster ให้ **ทนทาน ขยายได้ และปลอดภัยพอสำหรับองค์กร**
ครอบคลุม ConfigMap/Secret, Probes & HPA, Ingress/TLS, PV/PVC/StorageClass และ Container hardening / NetworkPolicy

---

## สารบัญ

1. [Configuration & Secrets](#1-configuration--secrets)
2. [Scalability & Health Probes](#2-scalability--health-probes)
3. [Horizontal Pod Autoscaling (HPA)](#3-horizontal-pod-autoscaling-hpa)
4. [Advanced Traffic Routing — Ingress & TLS](#4-advanced-traffic-routing--ingress--tls)
5. [Storage at Scale — PV, PVC, StorageClass](#5-storage-at-scale--pv-pvc-storageclass)
6. [Production Security](#6-production-security)
7. [หลักออกแบบ Resilience](#7-หลักออกแบบ-resilience)
8. [Best Practices สรุป](#8-best-practices-สรุป)

---

## 1. Configuration & Secrets

### แยก config ออกจาก image

Image ควรเป็น **immutable artifact** — ค่าที่ต่างต่อ environment ใส่ข้างนอก

| ชนิดข้อมูล           | กลไก K8s      | ตัวอย่าง                              |
| -------------------- | ------------- | ------------------------------------- |
| Non-sensitive config | **ConfigMap** | feature flag, log level, upstream URL |
| Sensitive            | **Secret**    | DB password, API token, TLS key       |

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
data:
  LOG_LEVEL: info
  UPSTREAM_URL: http://billing:8080
---
apiVersion: v1
kind: Secret
metadata:
  name: api-secret
type: Opaque
stringData:
  DATABASE_PASSWORD: 'change-me'
```

ฉีดเข้า Pod:

```yaml
envFrom:
 - configMapRef:
 name: api-config
 - secretRef:
 name: api-secret
# หรือ mount เป็นไฟล์
volumeMounts:
 - name: cfg
 mountPath: /etc/config
 readOnly: true
```

### ข้อควรรู้เรื่อง Secret

- Secret ใน etcd เป็น base64 (ไม่ใช่ encryption ที่แข็งแรงด้วยตัว alone) — เปิด **encryption at rest** และ RBAC จำกัดการอ่าน
- อย่า commit Secret จริงลง Git — ใช้ Sealed Secrets / External Secrets / SOPS ในงานจริง
- `stringData` สะดวกตอนเขียน YAML; API จะเก็บเป็น `data` (base64)

ตัวอย่าง: [`examples/01-configmaps-secrets/`](./examples/01-configmaps-secrets/)

---

## 2. Scalability & Health Probes

Kubernetes ตัดสินใจเรื่อง traffic และ restart จาก **probe**

| Probe         | คำถามที่ตอบ               | ผลเมื่อล้มเหลว                               |
| ------------- | ------------------------- | -------------------------------------------- |
| **Startup**   | สตาร์ทเสร็จหรือยัง?       | ฆ่าเมื่อเกิน failureThreshold — กันแอปช้าบูต |
| **Liveness**  | ยังมีชีวิตหรือค้าง?       | restart container                            |
| **Readiness** | พร้อมรับ traffic หรือยัง? | ถอดออกจาก Service endpoints                  |

```yaml
startupProbe:
  httpGet:
  path: /healthz
  port: 8080
  failureThreshold: 30
  periodSeconds: 5
livenessProbe:
  httpGet:
  path: /healthz
  port: 8080
  periodSeconds: 10
readinessProbe:
  httpGet:
  path: /readyz
  port: 8080
  periodSeconds: 5
```

### ออกแบบ endpoint ให้ถูก

| Endpoint          | ควรตรวจ                 | ไม่ควร                                           |
| ----------------- | ----------------------- | ------------------------------------------------ |
| `/healthz` (live) | process ตอบได้          | dependency ภายนอกที่อาจพลาดชั่วคราว → restart วน |
| `/readyz` (ready) | DB/cache ที่จำเป็นพร้อม | —                                                |

> Liveness ที่เข้มเกินทำให้ **restart storm**
> Readiness ที่หลวมเกินทำให้ผู้ใช้เจอ 5xx

ตัวอย่าง: [`examples/02-hpa-probes/`](./examples/02-hpa-probes/)

---

## 3. Horizontal Pod Autoscaling (HPA)

HPA ปรับ `replicas` ของ Deployment ตาม metric (CPU/memory หรือ custom)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
  apiVersion: apps/v1
  kind: Deployment
  name: api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
  resource:
  name: cpu
  target:
    type: Utilization
    averageUtilization: 70
```

### เงื่อนไขให้ HPA ทำงาน

1. มี **metrics-server** (Minikube: `minikube addons enable metrics-server`)
2. Pod กำหนด **resources.requests.cpu** (และ memory ถ้าใช้)
3. แอปจริง ๆ ใช้ CPU เมื่อโหลดเพิ่ม — ไม่งั้น scale ไม่มีความหมาย

```
Traffic ↑ → CPU ↑ → HPA เพิ่ม Pod → Service รวม endpoints ใหม่
Traffic ↓ → รอ stabilization → ลด replica (ไม่ต่ำกว่า minReplicas)
```

---

## 4. Advanced Traffic Routing — Ingress & TLS

**Service** ทำงานชั้น L4 (IP/port)
**Ingress** ทำงานชั้น L7 (HTTP path/host) ผ่าน **Ingress Controller**

```
Internet
 │
 ▼
Ingress Controller (nginx / traefik / cloud LB)
 │ rules: host + path + TLS
 ├── /api → Service backend:80
 └── / → Service frontend:80
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
 name: shop
 annotations:
 nginx.ingress.kubernetes.io/rewrite-target: /
spec:
 ingressClassName: nginx
 tls:
 - hosts: ["shop.example.local"]
 secretName: shop-tls
 rules:
 - host: shop.example.local
 http:
 paths:
  - path: /api
  pathType: Prefix
  backend:
  service:
  name: backend
  port:
   number: 80
  - path: /
  pathType: Prefix
  backend:
  service:
  name: frontend
  port:
   number: 80
```

### TLS termination

- Certificate เก็บใน Secret ชนิด `kubernetes.io/tls`
- Controller terminate TLS แล้วคุย HTTP ภายใน (หรือ mTLS ภายในถ้าออกแบบเพิ่ม)
- Local: `mkcert` / self-signed หรือ Minikube ingress addon

```bash
# Minikube
minikube addons enable ingress
```

ตัวอย่าง: [`examples/03-ingress-tls/`](./examples/03-ingress-tls/)

---

## 5. Storage at Scale — PV, PVC, StorageClass

สำหรับ stateful app (DB, queue ที่มี disk):

```
Pod → PersistentVolumeClaim (ขอความจุ) → PersistentVolume (ทรัพยากรจริง)
    ↑
   StorageClass (provisioner)
```

| object                          | บทบาท                                        |
| ------------------------------- | -------------------------------------------- |
| **PersistentVolume (PV)**       | ชิ้น storage ใน cluster                      |
| **PersistentVolumeClaim (PVC)** | คำขอจากผู้ใช้/แอป                            |
| **StorageClass**                | นโยบาย provision แบบ dynamic (เช่น CSI disk) |

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pgdata
spec:
  accessModes: ['ReadWriteOnce']
  resources:
  requests:
  storage: 5Gi
  storageClassName: standard
```

### Access modes

| Mode                | ความหมาย                                         |
| ------------------- | ------------------------------------------------ |
| ReadWriteOnce (RWO) | mount read-write ได้โหนดเดียว                    |
| ReadOnlyMany (ROX)  | อ่านหลายโหนด                                     |
| ReadWriteMany (RWX) | อ่านเขียนหลายโหนด (ต้อง storage รองรับ เช่น NFS) |

> บน Minikube มักมี StorageClass default อยู่แล้ว — dynamic provisioning สร้าง PV ให้เมื่อมี PVC

ตัวอย่าง: [`examples/04-persistent-storage/`](./examples/04-persistent-storage/)

---

## 6. Production Security

### Container hardening

| มาตรการ                 | ตัวอย่างใน Pod spec                                  |
| ----------------------- | ---------------------------------------------------- |
| Non-root                | `runAsNonRoot: true`, `runAsUser: 1000`              |
| Read-only root FS       | `readOnlyRootFilesystem: true` + emptyDir สำหรับ tmp |
| Drop capabilities       | `capabilities.drop: ["ALL"]`                         |
| No privilege escalation | `allowPrivilegeEscalation: false`                    |
| Seccomp                 | `seccompProfile.type: RuntimeDefault`                |

### NetworkPolicy

Default ในหลาย cluster คือ **อนุญาตทุก traffic**
NetworkPolicy จำกัดว่า Pod คุยกับใครได้ (ต้องมี CNI ที่รองรับ เช่น Calico, Cilium; Minikube อาจต้องเลือก CNI)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
 name: backend-allow
spec:
 podSelector:
 matchLabels:
 app: backend
 policyTypes: ["Ingress", "Egress"]
 ingress:
 - from:
 - podSelector:
  matchLabels:
  app: frontend
 ports:
 - protocol: TCP
  port: 3000
 egress:
 - to:
 - podSelector:
  matchLabels:
  app: db
 ports:
 - protocol: TCP
  port: 5432
```

ตัวอย่าง: [`examples/05-security-hardening/`](./examples/05-security-hardening/)

---

## 7. หลักออกแบบ Resilience

```
   ┌─ Startup/Liveness/Readiness
Desired replicas ───┤
   ├─ HPA (ยืดตามโหลด)
Git manifests ──────┤
   ├─ PDB (กัน drain แล้วเหลือ 0)
   ├─ Ingress + TLS
   └─ NetworkPolicy + non-root
```

| หลัก                      | ปฏิบัติ                                           |
| ------------------------- | ------------------------------------------------- |
| Fail closed สำหรับ secret | RBAC จำกัด `get secrets`                          |
| Zero-downtime deploy      | readiness + rollingUpdate `maxUnavailable`        |
| Stateful แยกคิด           | PVC + backup นโยบายชัด — อย่าใช้ emptyDir กับ DB  |
| Observability             | metrics-server + app metrics สำหรับ HPA ที่ดีขึ้น |
| Least privilege network   | อนุญาตเฉพาะ path ที่จำเป็น                        |

---

## 8. Best Practices สรุป

1. ConfigMap/Secret แยกจาก image — Secret ไม่ขึ้น Git แบบ plaintext
2. ใช้ครบคู่ **readiness + liveness** และเพิ่ม startup เมื่อบูตช้า
3. HPA ต้องมี requests + metrics-server
4. Ingress สำหรับ HTTP routing; TLS ที่ขอบ cluster
5. PVC + StorageClass สำหรับข้อมูลถาวร
6. securityContext และ NetworkPolicy เป็นชั้นป้องกันมาตรฐาน
7. ทดสอบ failure: ฆ่า Pod, ตัด DB, ยิงโหลด — ดูว่า self-heal / scale จริง
8. เอกสาร runbook สำหรับ Incident (ImagePull, CrashLoop, Pending PVC)

---

## ไฟล์ตัวอย่างในระดับนี้

| folder                                                                 | เนื้อหา                                  |
| ---------------------------------------------------------------------- | ---------------------------------------- |
| [`examples/01-configmaps-secrets/`](./examples/01-configmaps-secrets/) | ConfigMap + Secret + Deployment          |
| [`examples/02-hpa-probes/`](./examples/02-hpa-probes/)                 | Probes + HPA                             |
| [`examples/03-ingress-tls/`](./examples/03-ingress-tls/)               | Ingress path-based + TLS secret ตัวอย่าง |
| [`examples/04-persistent-storage/`](./examples/04-persistent-storage/) | PVC + Pod ใช้ volume                     |
| [`examples/05-security-hardening/`](./examples/05-security-hardening/) | securityContext + NetworkPolicy          |

เมื่อพร้อมแล้วไปที่ [`LAB.md`](./LAB.md) — สถานการณ์ production-ready ของ platform **AetherBank**
