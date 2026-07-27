# FinOps playbook สั้น ๆ สำหรับทีมคลาวด์

## รายสัปดาห์

- ตรวจ anomaly detection / budget alerts
- ลบ resource จาก lab ที่ไม่ถูก destroy
- รีวิว Spot/Preemptible interrupt rate ของ batch jobs

## รายเดือน

- Right-size: instance ที่ CPU p95 < 20% นาน 14 วัน
- Storage: lifecycle ครบทุก bucket สำคัญ
- Reserved / CUD coverage สำหรับ baseline load

## ก่อนเปิด multi-region

- ประมาณค่า NAT × 2, LB × 2, data transfer egress cross-region
- ตั้ง tag `cost-center` บังคับใน org policy
