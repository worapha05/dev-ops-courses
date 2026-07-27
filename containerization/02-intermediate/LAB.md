# Lab ระดับ Intermediate — ย้าย “ParcelGo API” ขึ้น Kubernetes

## เป้าหมาย

ทีมโลจิสติกส์จำลอง **ParcelGo** ต้องการ:

- สร้าง **multi-stage Dockerfile** ที่เล็กและรัน non-root
- สตาร์ท cluster ท้องถิ่น (Minikube หรือ Kind)
- Deploy ด้วย **Deployment + Service**
- เปิดให้ทดสอบจาก host ผ่าน **NodePort** (หรือ LoadBalancer + tunnel)
- ฝึกแก้ปัญหาเมื่อ Pod ไม่ Ready / ImagePullBackOff

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

ParcelGo มี API ตรวจสถานะพัสดุ (`GET /health`, `GET /api/parcels`)
เดิมรันด้วย Compose บนเครื่อง dev — ตอนนี้ต้องโชว์บน cluster ท้องถิ่นก่อนขึ้น staging จริง

ข้อกำหนดจาก Platform team:

> “Image ต้อง multi-stage, ฟัง port จาก `PORT`, และใน cluster ต้องมีอย่างน้อย 2 replicas หลัง Service ชนิด ClusterIP + NodePort สำหรับ demo”

---

## โจทย์

### ส่วนที่ 1 — Multi-stage image

ใน folder แอปของคุณ (หรือใช้เฉลยเป็นแนว):

1. เขียน Dockerfile แบบ multi-stage
2. มี `.dockerignore`
3. Build tag เป็น `parcelgo-api:1.0.0`
4. รันทดสอบด้วย `docker run` ให้ `curl /health` ผ่าน

### ส่วนที่ 2 — โหลด image เข้า cluster ท้องถิ่น

**Minikube**

```bash
minikube image load parcelgo-api:1.0.0
# หรือใช้ eval $(minikube docker-env) แล้ว build ใน docker ของ minikube
```

**Kind**

```bash
kind load docker-image parcelgo-api:1.0.0 --name bootcamp
```

ตั้งใน Deployment: `imagePullPolicy: IfNotPresent` (หรือ `Never` ถ้าระบุชัดว่าใช้ local image)

### ส่วนที่ 3 — Kubernetes Manifests

สร้างอย่างน้อย:

```text
k8s/deployment.yaml
k8s/service-clusterip.yaml
k8s/service-nodeport.yaml
```

ข้อกำหนด:

1. Deployment ชื่อ `parcelgo-api`, `replicas: 2`
2. Label `app: parcelgo-api`
3. Container port ตามแอป (เช่น 8080) และ `env PORT`
4. ClusterIP Service port 80 → targetPort ของแอป
5. NodePort Service สำหรับ demo (ระบุ `nodePort` คงที่ เช่น `30090` ได้)

### ส่วนที่ 4 — Verify & Scaling

```bash
kubectl apply -f k8s/
kubectl get pods -l app=parcelgo-api
kubectl get svc
kubectl scale deployment/parcelgo-api --replicas=3
kubectl rollout status deployment/parcelgo-api
```

ทดสอบจากใน cluster ด้วย curl Pod ชั่วคราว และจาก host ผ่าน NodePort / `minikube service`

### ส่วนที่ 5 — จำลอง Pod ล่มและแก้ปัญหา

1. ตั้ง image ผิดชื่อชั่วคราว → สังเกต `ImagePullBackOff` ด้วย `kubectl describe pod`
2. แก้กลับแล้ว `kubectl apply` / rollout
3. `kubectl delete pod` หนึ่งตัว — ยืนยันว่า ReplicaSet สร้างตัวใหม่ให้ครบ

### ส่วนที่ 6 — คำถามคิด (`NOTES.md`)

1. ทำไมต้องมี Service ทั้งที่ Pod มี IP อยู่แล้ว?
2. ClusterIP กับ NodePort ต่างกันอย่างไรในมุม security ของ demo ท้องถิ่น?
3. `imagePullPolicy: Always` กับ local image ที่ไม่ได้ push registry จะพังตรงไหน?

---

## เกณฑ์ผ่าน

- [ ] Multi-stage build สำเร็จ และรัน local ได้
- [ ] Deployment มีอย่างน้อย 2 replicas Ready
- [ ] ClusterIP + NodePort ใช้งานได้
- [ ] แสดงการ scale และ self-heal หลังลบ Pod ได้
- [ ] ตอบคำถามส่วนที่ 6
- [ ] Manifest ไม่ hardcode secret จริง

---

## คำใบ้

- Multi-stage: [`examples/01-multistage-dockerfile/`](./examples/01-multistage-dockerfile/)
- Cluster scripts: [`examples/03-local-cluster/`](./examples/03-local-cluster/)
- Service examples: [`examples/04-services-networking/`](./examples/04-services-networking/)

---

## เฉลย

อยู่ที่ [`lab/solution/`](./lab/solution/)
