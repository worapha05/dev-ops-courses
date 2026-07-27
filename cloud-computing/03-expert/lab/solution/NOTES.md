# เฉลยแนวคิด — NovaBank Expert Lab

## ส่วนที่ 1 — Modules & Backend

ใช้ `src/terraform/modules/*` และ bootstrap จาก `src/terraform/backend/*`
แยก state key:

- `ccp/dev/terraform.tfstate`
- `ccp/staging/terraform.tfstate`
- `ccp/prod/terraform.tfstate`

IAM แนะนำ: CI role ทำ `plan` ได้ทุก env, `apply` ได้เฉพาะผ่าน protected environment + approval

## ส่วนที่ 2 — DR

ดู `runbooks/failover.md` และ `runbooks/failback.md`
Terraform อ้างอิง: `../../src/terraform/multi-cloud/`

## ส่วนที่ 3 — Observability

ใช้ `src/observability/` เป็น baseline
Golden signals ต้อง map ไปที่ ALB/Cloud Run metrics ไม่ใช่แค่ host CPU

## ส่วนที่ 4 — FinOps

รัน `src/finops/cost-hygiene.sh` แล้วแปะผลในรายงาน lab
Tag ขั้นต่ำ: `env`, `owner`, `cost-center`, `service`

## สิ่งที่ Board อยากได้ใน 1 หน้า

| หัวข้อ  | คำตอบสั้น                              |
| ------- | -------------------------------------- |
| RTO/RPO | ≤1h / ≤15m ด้วย warm standby + replica |
| IaC     | Terraform modules + remote lock        |
| Drift   | nightly plan exit code 2               |
| Cost    | budgets + hygiene script + no idle NAT |
