# AetherBank Release Runbook

## ลำดับปล่อย (Happy path)

1. PR ผ่าน `quality` + `sast` (+ build/scan บน CI)
2. Merge เข้า `main`
3. Pipeline สร้าง image tag `sha-<commit>`
4. Deploy **staging** ด้วย tag เดิม → smoke `/health`
5. Reviewer approve GitHub Environment **production** (หรือ Jenkins `input`)
6. Deploy GREEN → smoke → สลับ LB Blue→Green

## ใคร approve production

- On-call engineer + tech lead (ตั้งใน GitHub Environment Required reviewers)
- ห้ามคนเดียวที่เป็นคนสร้าง change เป็น reviewer คนเดียวถ้า policy องค์กรห้าม

## Rollback (< 5 นาที)

1. สลับ LB กลับ BLUE=100%
2. ยืนยัน `/health` และ error rate
3. เปิด incident note: tag ที่พัง, เวลา cutover, ผู้ approve

ถ้าใช้ canary: ตั้ง weight canary=0 ทันที แล้ววิเคราะห์เมตริก

## เมื่อ Trivy fail

1. อ่าน CVE / misconfig จาก log
2. update base image หรือ dependency
3. ถ้าเป็น false positive ที่ยอมรับได้ — บันทึกเหตุผลใน `trivyignore` พร้อมวันหมดอายุ (อย่า ignore ทั้งโลก)
4. ห้ามปิด `exit-code` เพื่อให้ deploy ผ่านแบบเงียบ ๆ
