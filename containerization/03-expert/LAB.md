# Lab ระดับ Expert — Production Hardening ของ “AetherBank”

## เป้าหมาย

platform ธนาคารจำลอง **AetherBank** ต้องการยกระดับ API บน Kubernetes ให้ใกล้ production:

- แยก config / secret ออกจาก image
- ใส่ Startup / Liveness / Readiness probes
- ตั้ง HPA ตาม CPU
- เปิด Ingress แบบ path-based พร้อม TLS
- ใช้ PVC สำหรับบริการที่มี state (เช่น Postgres)
- ใส่ securityContext และ NetworkPolicy พื้นฐาน
- ซ้อมแก้ปัญหา **CrashLoopBackOff / Pod ไม่ Ready / PVC Pending**

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

AetherBank มี Deployment `ledger-api` ที่ตอนนี้:

- hardcode password ใน YAML
- ไม่มี probe → Service ส่ง traffic เข้า instance ที่ยังต่อ DB ไม่ได้
- replicas คงที่ = 1 → โหลดพุ่งแล้วช้า
- เปิด NodePort ตรง ๆ ไม่มี TLS ที่ขอบ
- ฐานข้อมูลใช้ emptyDir → รีสตาร์ทแล้วข้อมูลหาย

CISO ออก Definition of Done:

> “ต้องมี ConfigMap+Secret, probes ครบ, HPA min 2, Ingress+TLS, PVC สำหรับ DB, และ container รัน non-root พร้อม NetworkPolicy จำกัดทางเข้า API”

---

## โจทย์

### ส่วนที่ 1 — Config & Secret

1. สร้าง ConfigMap สำหรับ `LOG_LEVEL`, `APP_ENV`
2. สร้าง Secret สำหรับ `DB_USER`, `DB_PASSWORD` (ค่า demo)
3. ฉีดเข้า Deployment ผ่าน `env` / `envFrom` — **ห้าม** ใส่ password เป็น plaintext ใน container env ตรง ๆ ในไฟล์เดียวกับที่ commit ถ้าแยก secret ได้ให้แยก

### ส่วนที่ 2 — Probes & HPA

1. เพิ่ม `startupProbe`, `livenessProbe`, `readinessProbe` ให้ `ledger-api`
2. กำหนด `resources.requests/limits`
3. สร้าง HPA: min 2, max 8, CPU target ~60–70%
4. เปิด metrics-server บน cluster ท้องถิ่น

### ส่วนที่ 3 — Ingress & TLS

1. เปิด Ingress controller
2. สร้าง self-signed TLS Secret
3. Ingress host เช่น `aether.local`:

- `/api` → `ledger-api` Service
- `/` → frontend Service (จะใช้ http-echo หรือ static ก็ได้)

### ส่วนที่ 4 — Storage

1. สร้าง PVC สำหรับ Postgres (1–5Gi)
2. Deployment/StatefulSet ของ DB ใช้ PVC นั้น
3. พิสูจน์ว่าลบ Pod DB แล้วข้อมูล seed ยังอยู่

### ส่วนที่ 5 — Security

1. `securityContext` ระดับ Pod/Container: non-root, drop ALL caps, no privilege escalation
2. NetworkPolicy: อนุญาต ingress เข้า `ledger-api` จาก Ingress controller / frontend เท่านั้น (อย่างน้อย demark แนวคิดใน YAML)

### ส่วนที่ 6 — Chaos & Troubleshooting

จำลองและจดขั้นตอนแก้ใน `RUNBOOK.md`:

1. ใส่ readiness path ผิด → Pod ไม่เข้า endpoints
2. ใส่ DB password ผิด → CrashLoop หรือ ready ไม่ผ่าน
3. ลบ PVC โดยไม่ตั้งใจ (บน lab เท่านั้น) → Pending / ข้อมูลหาย — อธิบายป้องกันอย่างไร

### ส่วนที่ 7 — คำถามคิด (`NOTES.md`)

1. ทำไม liveness ไม่ควร ping database โดยตรง?
2. HPA ไม่ขยายทั้งที่โหลดสูง — สาเหตุที่เป็นไปได้ 3 ข้อ?
3. ความต่างของ Secret ใน K8s กับ password manager ขององค์กรคืออะไร?

---

## เกณฑ์ผ่าน

- [ ] ConfigMap + Secret ถูก inject
- [ ] Probes ครบและ HPA apply ได้
- [ ] Ingress + TLS ตอบจาก host ได้ (หรืออธิบายข้อจำกัด WSL/Minikube ได้ชัด)
- [ ] PVC ผูกกับ DB และทนต่อ delete Pod
- [ ] มี securityContext + NetworkPolicy
- [ ] มี RUNBOOK สั้น ๆ จากส่วนที่ 6
- [ ] ตอบ NOTES ส่วนที่ 7

---

## คำใบ้

- [`examples/01-configmaps-secrets/`](./examples/01-configmaps-secrets/)
- [`examples/02-hpa-probes/`](./examples/02-hpa-probes/)
- [`examples/03-ingress-tls/`](./examples/03-ingress-tls/)
- [`examples/04-persistent-storage/`](./examples/04-persistent-storage/)
- [`examples/05-security-hardening/`](./examples/05-security-hardening/)

---

## เฉลย

อยู่ที่ [`lab/solution/`](./lab/solution/)
