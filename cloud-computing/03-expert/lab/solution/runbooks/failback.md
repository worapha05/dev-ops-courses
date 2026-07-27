# Runbook — Failback

ทำเมื่อ PRIMARY region เสถียรและได้รับอนุมัติจาก Incident Commander

## ขั้นตอน

1. หยุด traffic ใหม่บน SECONDARY ชั่วคราวหรือเปิด maintenance (ถ้าจำเป็นตาม RPO)
2. Sync ข้อมูลกลับ PRIMARY (DB promote/demote ตามเทคโนโลยีที่ใช้)
3. ตรวจ `/healthz` และ synthetic canary บน PRIMARY
4. สลับ DNS PRIMARY กลับด้วย Route 53 / Global LB
5. Scale secondary ลงสู่ warm capacity เพื่อประหยัดค่า
6. เขียน postmortem: สาเหตุ, timeline, action items (รวม drift/FinOps ถ้าเกี่ยว)

## ตรวจหลัง failback 24 ชม.

- [ ] ไม่มี error spike จาก client cache DNS
- [ ] Replication กลับทิศทางปกติ
- [ ] Terraform state ตรงกับ infrastructure จริง (`drift-check.sh`)
