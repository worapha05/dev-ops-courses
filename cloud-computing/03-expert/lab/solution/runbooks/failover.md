# Runbook — Failover (Active-Passive)

**บริการ:** NovaBank API
**โหมด:** PRIMARY `ap-southeast-1` → SECONDARY `ap-northeast-1`
**ทริกเกอร์:** health check `/healthz` ล้ม ≥ 3 ครั้ง หรือประกาศจาก Incident Commander

## ก่อนเริ่ม

- [ ] เปิด war room / ช่อง `#inc-novabank`
- [ ] ยืนยันว่า secondary warm standby healthy
- [ ] ตรวจ replication lag ของ DB/object ว่าอยู่ใน RPO

## ขั้นตอน

1. **ยืนยันอาการ**

```bash
./src/cli/aws/simulate-failover-check.sh http://PRIMARY_ALB/healthz
```

2. **ถ้าใช้ Route 53 failover อัตโนมัติ** — รอ DNS failover และตรวจ

```bash
dig +short app.example.com
curl -fsS https://app.example.com/healthz
```

3. **ถ้าต้อง failover มือ** — ลด weight/primary หรือ update record ไป secondary (ผ่าน Terraform หรือ console ตาม change window)
4. **Scale up secondary**

```bash
aws autoscaling set-desired-capacity --auto-scaling-group-name ASG_SECONDARY --desired-capacity 4
```

5. **ประกาศสถานะ** แก่ลูกค้าภายใน (status page)
6. **เฝ้า metrics** error rate / p95 15–30 นาที

## เกณฑ์สำเร็จ

- [ ] ผู้ใช้ส่วนใหญ่เข้า SECONDARY ได้
- [ ] Error rate กลับใกล้ baseline
- [ ] ไม่มี write ไป PRIMARY ที่กำลังพัง (กัน split-brain)

## สิ่งที่ห้ามทำ

- Failback ทันทีที่ PRIMARY กลับมาโดยไม่ดู data lag
- เปิด DB primary สองตัวรับ write พร้อมกันโดยไม่มี consensus/plan
