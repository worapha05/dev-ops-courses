# ShopFlow — Security notes สำหรับ Lab Intermediate

## ทำไมห้าม commit token

- Git history ลบยาก — แม้ลบไฟล์ใน commit ถัดไป ค่ายังอยู่ในประวัติ
- Public fork / leaked laptop = credential หลุดทันที
- Audit ทำไม่ได้ว่าใครใช้ token จากที่ไหน

## แนวปฏิบัติที่ Lab นี้ย้ำ

1. เก็บ token ใน GitHub Secrets หรือ Jenkins Credentials เท่านั้น
2. ใน log แสดงได้แค่ความยาวหรือสถานะ มี/ไม่มี
3. ใช้ Environment secrets สำหรับของ production พร้อม reviewers
4. Rotate ทันทีเมื่อสงสัยว่าหลุด
