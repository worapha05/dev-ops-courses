# 04 — SAST: Trivy & SonarQube

| ไฟล์                                           | เนื้อหา                                                  |
| ---------------------------------------------- | -------------------------------------------------------- |
| [`trivy-scan.yml`](./trivy-scan.yml)           | สแกน filesystem + image แล้ว fail เมื่อเจอ HIGH/CRITICAL |
| [`sonar-scan.yml`](./sonar-scan.yml)           | โครง SonarCloud/SonarQube scan                           |
| [`secure-pipeline.yml`](./secure-pipeline.yml) | รวม test → trivy fs → build → trivy image                |

## ตั้งค่า

- Trivy: ไม่บังคับ token สำหรับ public advisory DB พื้นฐาน
- Sonar: ต้องมี `SONAR_TOKEN` และตั้ง `sonar-project.properties` หรือ parameter ใน action
