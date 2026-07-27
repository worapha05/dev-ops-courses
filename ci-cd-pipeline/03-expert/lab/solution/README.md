# เฉลย Lab Expert — AetherBank Delivery

| ไฟล์                                                                                       | คำอธิบาย                                       |
| ------------------------------------------------------------------------------------------ | ---------------------------------------------- |
| [`.github/workflows/aetherbank-delivery.yml`](./.github/workflows/aetherbank-delivery.yml) | Secure multi-stage delivery + blue-green จำลอง |
| [`Jenkinsfile`](./Jenkinsfile)                                                             | Jenkins เทียบเท่าพร้อม approval                |
| [`RUNBOOK.md`](./RUNBOOK.md)                                                               | คู่มือปฏิบัติการ                               |
| [`NOTES.md`](./NOTES.md)                                                                   | เฉลยคำถามคิด                                   |

## หมายเหตุ

- Trivy อาจ fail ถ้า base image มี CVE — ใน lab จริงให้แก้ด้วย update base image หรือ `trivyignore` อย่างมีเหตุผล (อย่าปิด `exit-code` ทิ้ง)
- Environment `production` ต้องสร้างใน GitHub และใส่ Required reviewers เอง
