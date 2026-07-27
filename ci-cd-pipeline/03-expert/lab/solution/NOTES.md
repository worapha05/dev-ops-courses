# เฉลยคำถามคิด — Lab Expert

## 1. ทำไมต้องใช้ digest/tag เดียวจาก staging → production?

เพื่อให้สิ่งที่ทดสอบบน staging **คือบิตเดียวกับที่ขึ้น prod**
ถ้า build ใหม่ตอน promote อาจได้ dependency/layer ต่างกัน แม้ source SHA เดิม — ความมั่นใจของ staging หายไป

## 2. OIDC ดีกว่า JSON key ระยะยาวอย่างไร?

- ได้ token ชั่วคราวตาม workflow run — ลดหน้าต่างถ้าหลุด
- ไม่ต้องหมุน key ไฟล์ใน Secrets บ่อยเท่า
- ผูก trust กับ repo/branch/environment ได้ละเอียดบน cloud IAM

## 3. Canary ผ่านแต่ migration irreversible

Traffic/app อาจดูดี แต่ schema ที่เปลี่ยนแล้ว **rollback แอปอย่างเดียวไม่พอ**
ต้องมีแผน migration แบบ expand/contract, backward-compatible steps หรือ backup/restore ที่ซ้อมแล้ว ไม่งั้น canary “เขียว” แต่ data layer ย้อนไม่ได้
