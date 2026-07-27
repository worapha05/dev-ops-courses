# Lab ระดับ Expert — "NovaBank Global" Multi-Region + IaC + FinOps

## เป้าหมาย

ออกแบบ platform ธนาคารจำลอง **NovaBank** ที่ต้อง:

1. Automate ด้วย Terraform modules + remote state ปลอดภัย
2. รองรับ Disaster Recovery แบบ Active-Passive (อย่างน้อย) พร้อมเส้นทางไป Active-Active
3. มี Observability (logs/metrics/traces) และ alert ที่ actionable
4. คุมต้นทุนด้วย FinOps practices และตรวจ infrastructure drift

ทำด้วยตัวเองก่อน แล้วเทียบ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

NovaBank ให้บริการ API ชำระเงินใน SEA
ข้อกำหนดจาก Board:

> - RPO ≤ 15 นาที, RTO ≤ 1 ชั่วโมง สำหรับภูมิภาคหลัก
> - IaC เท่านั้นสำหรับ prod — ห้ามคลิกสร้าง resource วิกฤตใน console
> - ตรวจเจอ drift ภายใน 24 ชม.
> - งบ cloud ต้องมี anomaly alert และ tag ต้นทุนครบ

เหตุการณ์ที่เกิดขึ้นในสัปดาห์เดียว:

1. Engineer แก้ Security Group มือใน console → Terraform state กับจริงไม่ตรง
2. Region หลัก (`ap-southeast-1`) มี degradations ที่ ALB — ต้อง failover
3. Bill พุ่งจาก NAT Gateway ค้างในบัญชี lab + data transfer ข้าม region ที่ออกแบบผิด
4. On-call ไม่มี trace id ทำให้หา root cause ช้า

---

## โจทย์

### ส่วนที่ 1 — Terraform Architecture

ส่งมอบ:

1. แผนผัง modules (`network`, `compute`, `storage`, `database`) และการประกอบใน `dev/staging/prod`
2. ออกแบบ remote backend (S3+DynamoDB และ/หรือ GCS) พร้อม IAM ใคร plan/apply ได้
3. script/CI ที่รัน `terraform plan -detailed-exitcode` แล้วแจ้งเมื่อ drift

ใช้ของใน `src/terraform/` เป็นฐานได้

### ส่วนที่ 2 — DR Design

เลือกและชี้แจง:

- [ ] Active-Passive ด้วย Route 53 failover **หรือ** Global HTTPS LB บน GCP
- [ ] วิธี replicate ข้อมูล (object + DB) และผลกระทบ RPO
- [ ] Runbook failover / failback ทีละขั้น (รวมการสื่อสารสถานะ)
- [ ] เกณฑ์ promote secondary → primary

### ส่วนที่ 3 — Observability & Incident

1. กำหนด golden signals สำหรับ API NovaBank
2. สร้างอย่างน้อย 2 alarms (error rate, latency)
3. อธิบายการผูก trace ↔ logs ด้วย correlation id
4. จำลอง: primary `/healthz` ล้ม — ใช้ script ตรวจและตัดสินใจ failover

### ส่วนที่ 4 — FinOps

1. รัน/เขียน checklist หา idle EIP, NAT, LB ที่ไม่ใช้
2. ประมาณค่าเพิ่มเมื่อเปิด warm standby region ที่สอง
3. เสนอ tagging policy ขั้นต่ำ 4 keys

### ส่วนที่ 5 — Multi-Cloud (โบนัสคะแนนเต็ม)

ออกแบบให้ artifact สำคัญ replicate ไป GCS หรือกลับกัน พร้อมเหตุผล (ไม่บังคับให้ผลิต traffic จริงทุกเส้นทาง)

---

## เกณฑ์ตรวจ

- [ ] มี modules แยกและ env ประกอบชัด
- [ ] Remote state + locking
- [ ] DR runbook ครบ failover/failback
- [ ] Alarms + drift check
- [ ] FinOps findings มีตัวเลขหรือคำสั่งจริง

---

## เฉลยวิธีคิด (อ่านหลังทำ)

### IaC

```text
backend (S3/GCS)
  ↑
prod/main.tf → module.network / compute / storage / database
    ↑
  modules/* (reusable, versioned)
```

Drift: CI รายวัน `plan -detailed-exitcode` → ถ้า = 2 เปิด ticket บังคับ reconcile (apply หรือ revert console change)

### DR Active-Passive

```text
Route 53 failover
  PRIMARY → ALB region A + health check /healthz
  SECONDARY → ALB region B (warm: desired_capacity ต่ำกว่าได้)
```

ข้อมูล: S3 CRR / GCS dual-region + DB replica cross-region
Failback: อย่ารีบสลับกลับจนกว่า region A stable และ data catch-up ครบ

### Observability

| Signal     | ตัวอย่าง metric                 |
| ---------- | ------------------------------- |
| Rate       | requests/sec                    |
| Errors     | 5xx ratio                       |
| Duration   | p95 latency                     |
| Saturation | CPU/concurrency, DB connections |

### FinOps

เปิด region สอง = คิด NAT+LB+egress เป็นค่าคงที่ก่อนคุย Active-Active
ใช้ Spot เฉพาะ batch ไม่ใช่ ledger path

รายละเอียด: [`lab/solution/`](./lab/solution/) โดยเฉพาะ `runbooks/failover.md`
