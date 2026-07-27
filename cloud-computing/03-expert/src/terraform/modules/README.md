# Terraform Modules (Expert)

| Module   | Path                         | Cloud   | หน้าที่               |
| -------- | ---------------------------- | ------- | --------------------- |
| network  | `network/aws`, `network/gcp` | ทั้งคู่ | VPC/subnet/NAT        |
| storage  | `storage/aws`, `storage/gcp` | ทั้งคู่ | Private object bucket |
| compute  | `compute/aws`                | AWS     | ALB + ASG             |
| database | `database/aws`               | AWS     | RDS PostgreSQL HA     |

ประกอบใช้งานได้ที่ `../aws`, `../gcp`, `../multi-cloud`
