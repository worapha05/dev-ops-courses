# เฉลยแนวคิด — PayFlow Intermediate Lab

## สิ่งที่ต้องมีในคำตอบที่ผ่าน

1. สามชั้น subnet + HA DB private
2. Runtime อ่าน secret ผ่าน IAM ไม่ผ่านไฟล์ใน Git
3. Autoscaling ที่ชั้นแอป
4. Runbook INC-1…INC-4 ที่รันคำสั่งจริงได้

## โครงสร้างเฉลย

```text
lab/solution/
├── NOTES.md
├── cli/
│ ├── rotate-and-redeploy.sh
│ └── check-db-sg.sh
└── terraform/
 ├── aws/ # สำเนาจาก src/terraform/aws
 └── gcp/
```

Terraform หลักอยู่ที่ `../../src/terraform/` — folder นี้คัดลอกมาเป็น baseline ของเฉลย

## ลำดับ Apply ที่แนะนำ (ลดความล้มเหลว)

1. VPC (+ NAT)
2. Secrets placeholder / IAM
3. DB
4. update secret ให้มี host จริง
5. ECS / Cloud Run
6. ทดสอบ `/healthz` แล้วค่อย load test

## Scale เมื่อ RPS ×3

| ชั้น       | ทำอะไร                                    | ไม่ทำอะไร                                 |
| ---------- | ----------------------------------------- | ----------------------------------------- |
| API        | เพิ่ม max tasks / Cloud Run max instances | เปิด DB สู่ internet                      |
| DB         | เพิ่ม read replica ถ้าอ่านหนัก            | vertical ทันทีโดยไม่ดู slow query         |
| Secret/IAM | คง PoLP                                   | ติด `AdministratorAccess` เพื่อ "ให้ผ่าน" |

## Cleanup

```bash
terraform destroy -auto-approve
# ตรวจ NAT EIP / idle LB / Cloud SQL ที่ค้าง
```
