# เฉลย Lab Beginner — NovaPay CI

## ไฟล์สำคัญ

| ไฟล์                                                                                 | คำอธิบาย                             |
| ------------------------------------------------------------------------------------ | ------------------------------------ |
| [`.github/workflows/novapay-ci.yml`](./.github/workflows/novapay-ci.yml)             | GitHub Actions แบบ job เดียวครบ      |
| [`.github/workflows/novapay-ci-split.yml`](./.github/workflows/novapay-ci-split.yml) | แบบแยก lint / test + `needs`         |
| [`jenkins/freestyle-build.sh`](./jenkins/freestyle-build.sh)                         | script ใส่ใน Freestyle Execute shell |
| [`NOTES.md`](./NOTES.md)                                                             | เฉลยคำถามคิด                         |

## วิธีใช้เฉลย Actions

คัดลอก workflow ไปที่ root ของ repo:

```bash
mkdir -p .github/workflows
cp 01-beginner/lab/solution/.github/workflows/novapay-ci.yml .github/workflows/
```

จากนั้น push ขึ้น GitHub แล้วดูแท็บ **Actions**

## วิธีใช้เฉลย Jenkins

1. สร้าง Freestyle `novapay-freestyle-ci`
2. วางเนื้อหา `jenkins/freestyle-build.sh` ใน Execute shell (ปรับ `APP_DIR` ให้ตรง workspace)
