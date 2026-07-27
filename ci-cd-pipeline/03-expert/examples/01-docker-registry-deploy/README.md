# 01 — Docker Registry & Cloud Deploy

| ไฟล์                                                       | เนื้อหา                              |
| ---------------------------------------------------------- | ------------------------------------ |
| [`ghcr-build-push.yml`](./ghcr-build-push.yml)             | Build multi-stage image → push GHCR  |
| [`cloudrun-deploy.yml`](./cloudrun-deploy.yml)             | ตัวอย่าง deploy Google Cloud Run     |
| [`aws-ecr-ecs.yml`](./aws-ecr-ecs.yml)                     | ตัวอย่าง push ECR + update ECS (ย่อ) |
| [`Jenkinsfile.docker-deploy`](./Jenkinsfile.docker-deploy) | Jenkins แนว build/push               |

> แทนที่ชื่อ project/region/service ด้วยของจริงก่อนรัน
> Secrets ที่อ้างต้องสร้างใน GitHub/Jenkins ก่อน
