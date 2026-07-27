# Level 3 — Expert: Enterprise Delivery, Security & Cloud Deployment

เป้าหมายระดับนี้: ออกแบบ pipeline ระดับ production ที่ **build image → push registry → deploy cloud**
พร้อมกลยุทธ์ **Blue-Green / Canary / Manual Approval**, **dependency caching**, และ **SAST (Trivy / SonarQube)**

---

## สารบัญ

1. [Production-Ready Multi-stage Pipelines](#1-production-ready-multi-stage-pipelines)
2. [Container Registry และ Tagging Strategy](#2-container-registry-และ-tagging-strategy)
3. [Deploy ไป Google Cloud Run / AWS](#3-deploy-ไป-google-cloud-run--aws)
4. [Deployment Strategies](#4-deployment-strategies)
5. [Manual Approval Gates](#5-manual-approval-gates)
6. [Pipeline Optimization — Caching & Runners](#6-pipeline-optimization--caching--runners)
7. [Pipeline Security — SAST ด้วย Trivy / SonarQube](#7-pipeline-security--sast-ด้วย-trivy--sonarqube)
8. [Best Practices สรุป](#8-best-practices-สรุป)

---

## 1. Production-Ready Multi-stage Pipelines

Pipeline องค์กรที่ดีมักแยกเป็นชั้น:

```
CI (ทุก PR)
 lint → unit test → SAST (เร็ว) → build check

CD (main / release tag)
 build image → scan image → push registry
 → deploy staging → smoke test
 → approval → deploy production (blue-green/canary)
```

### หลักออกแบบ

| หลัก                   | ปฏิบัติ                                                           |
| ---------------------- | ----------------------------------------------------------------- |
| Fail fast ก่อนของแพง   | test/SAST ก่อน `docker build` / deploy                            |
| Immutable artifact     | image digest/tag จาก commit SHA ไม่ใช่ “latest” เป็นแหล่งความจริง |
| Same artifact ข้าม env | staging กับ prod ใช้ image digest เดียวกัน                        |
| Separated privileges   | token ตอน CI ≠ token ตอน deploy prod                              |
| Observability          | หลัง deploy ต้องมี health check / metrics                         |

ตัวอย่าง: [`examples/01-docker-registry-deploy/`](./examples/01-docker-registry-deploy/)

---

## 2. Container Registry และ Tagging Strategy

### Registry ที่พบบ่อย

- **Docker Hub** — เริ่มง่าย, rate limit ต้องระวัง
- **GHCR (`ghcr.io`)** — ใกล้ GitHub Actions, สิทธิ์ผูก GitHub
- **Artifact Registry / ECR** — ใกล้ GCP / AWS ตามลำดับ

### Tagging ที่แนะนำ

```text
ghcr.io/<org>/sample-app:sha-abc1234 # immutable ต่อ commit
ghcr.io/<org>/sample-app:main  # floating tag ของ branch (optional)
ghcr.io/<org>/sample-app:1.4.2  # semver เมื่อ release
ghcr.io/<org>/sample-app:1.4.2-build.88 # semver + build metadata
```

> หลีกเลี่ยงการ deploy ด้วย `:latest` เป็นหลัก — rollback และ audit ยาก

ตัวอย่าง login + push:

```yaml
- uses: docker/login-action@v3
 with:
 registry: ghcr.io
 username: ${{ github.actor }}
 password: ${{ secrets.GITHUB_TOKEN }}

- uses: docker/build-push-action@v6
 with:
 context: ./01-beginner/sample-app
 push: true
 tags: |
 ghcr.io/${{ github.repository_owner }}/sample-app:sha-${{ github.sha }}
 ghcr.io/${{ github.repository_owner }}/sample-app:main
```

---

## 3. Deploy ไป Google Cloud Run / AWS

แนวคิดเหมือนกัน: **ได้ image ใน registry แล้วสั่ง platform รัน revision ใหม่**

### Google Cloud Run (แนว Actions)

ความลับที่มักต้องมี:

- `GCP_PROJECT_ID`
- `GCP_SA_KEY` (JSON ของ service account) หรือ Workload Identity Federation (แนะนำกว่า key ไฟล์)
- สิทธิ์ `run.admin`, `artifactregistry` ตามที่ออกแบบ

```yaml
- uses: google-github-actions/auth@v2
 with:
 credentials_json: ${{ secrets.GCP_SA_KEY }}

- uses: google-github-actions/deploy-cloudrun@v2
 with:
 service: sample-app
 image: REGION-docker.pkg.dev/PROJECT/REPO/sample-app:sha-${{ github.sha }}
 region: asia-southeast1
```

### AWS (ECS/App Runner/EKS — ย่อ)

- build → push **ECR**
- update บริการ (ECS task definition / App Runner / Helm บน EKS)
- ใช้ OIDC จาก GitHub → IAM role แทน access key ยาว ๆ เมื่อทำได้

ไฟล์ตัวอย่างแยก Cloud Run และ ECS แบบย่ออยู่ใน [`examples/01-docker-registry-deploy/`](./examples/01-docker-registry-deploy/)

> Lab Expert เน้น **โครง workflow ที่ถูกต้อง** — การสร้าง cloud project จริงขึ้นกับบัญชีของคุณ

---

## 4. Deployment Strategies

### Blue-Green

มีสองสภาพแวดล้อม (blue = ปัจจุบัน, green = ใหม่)
deploy ไปฝั่งที่ไม่รับ traffic แล้ว **สลับ router/load balancer** เมื่อพร้อม

```
Users → LB ┬→ Blue (v1) active
  └→ Green (v2) idle → หลังทดสอบ → สลับเป็น active
```

| ข้อดี                      | ข้อเสีย                                 |
| -------------------------- | --------------------------------------- |
| Rollback เร็ว (สลับกลับ)   | ใช้ทรัพยากรเกือบ 2 เท่าช่วงตัดover      |
| ทดสอบบน infra จริงก่อนสลับ | ต้องจัดการ DB migration อย่างระมัดระวัง |

### Canary

ปล่อยของใหม่ให้ผู้ใช้ส่วนน้อยก่อน (เช่น 5% → 25% → 100%)

```
Users → LB → 95% v1
  → 5% v2 (canary) ──ดู error/latency──▶ promote / rollback
```

| ข้อดี                  | ข้อเสีย                         |
| ---------------------- | ------------------------------- |
| ลด blast radius        | ต้องการ metrics + routing ที่ดี |
| ค่อย ๆ เพิ่มความมั่นใจ | ซับซ้อนกว่า rolling ธรรมดา      |

### Rolling (เทียบสั้น ๆ)

แทนที่ instance ทีละชุด — ใช้ทรัพยากรน้อยกว่า blue-green แต่ rollback อาจช้ากว่าการสลับทั้งก้อน

ตัวอย่าง workflow จำลอง: [`examples/02-blue-green-canary/`](./examples/02-blue-green-canary/)

---

## 5. Manual Approval Gates

แม้ Continuous Deployment จะปล่อยอัตโนมัติ แต่หลายองค์กรใส่ **human gate** ก่อน production

### GitHub Environments

1. Settings → Environments → สร้าง `production`
2. เปิด **Required reviewers**
3. จำกัด deployment branches เป็น `main`

```yaml
deploy-prod:
  needs: [deploy-staging]
  runs-on: ubuntu-latest
  environment:
  name: production
  url: https://app.example.com
  steps:
    - run: echo "deploy after approval"
```

เมื่อ job ถึงขั้นนี้ workflow จะ **รอ approve** ใน UI

### Jenkins Input

```groovy
stage('Approve production') {
 steps {
 input message: 'Deploy to production?', ok: 'Deploy'
 }
}
```

ใส่ `timeout` รอบ `input` เพื่อไม่ให้ค้างforever

---

## 6. Pipeline Optimization — Caching & Runners

### Dependency caching

| Ecosystem | Cache key พื้นฐาน                  |
| --------- | ---------------------------------- |
| npm       | `package-lock.json` hash           |
| pip       | `requirements.txt` / `poetry.lock` |
| go        | `go.sum`                           |

GitHub Actions:

```yaml
- uses: actions/setup-node@v4
 with:
 node-version: "20"
 cache: npm
 cache-dependency-path: 01-beginner/sample-app/package-lock.json
```

หรือ `actions/cache@v4` แบบกำหนดเอง

### แนวลดเวลา/ค่าใช้จ่าย

1. แยก job หนักเฉพาะตอนต้องการ (path filters)
2. Matrix เท่าที่สัญญา compatibility
3. ใช้ remote cache ของ Docker layer (`cache-from` / GitHub cache backend)
4. Self-hosted runners สำหรับงานที่ต้องการเครือข่ายภายใน / GPU / ใหญ่พิเศษ
5. `concurrency` ยกเลิก run เก่าของ branch เดียวกัน

```yaml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: true
```

ตัวอย่าง: [`examples/03-caching-optimization/`](./examples/03-caching-optimization/)

---

## 7. Pipeline Security — SAST ด้วย Trivy / SonarQube

### SAST คืออะไร

**Static Application Security Testing** = วิเคราะห์โค้ด/image/IaC โดยยังไม่ต้องรันแอปแบบ attacker
เป้าหมาย: เจอ vulnerability, misconfig, secret ฝังโค้ด ก่อนขึ้น production

### Trivy (Aqua)

สแกนได้หลายเป้า: filesystem, image, IaC, secrets

```yaml
- name: Trivy fs scan
 uses: aquasecurity/trivy-action@0.28.0
 with:
 scan-type: fs
 scan-ref: 01-beginner/sample-app
 severity: HIGH,CRITICAL
 exit-code: "1"

- name: Trivy image scan
 uses: aquasecurity/trivy-action@0.28.0
 with:
 image-ref: ghcr.io/org/sample-app:sha-${{ github.sha }}
 severity: HIGH,CRITICAL
 exit-code: "1"
```

### SonarQube / SonarCloud

เน้นคุณภาพโค้ด + security hotspot ผ่าน static analysis ของภาษา

```yaml
- name: SonarCloud Scan
 uses: SonarSource/sonarqube-scan-action@v4
 env:
 SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

| เครื่องมือ | จุดเด่นใน pipeline                                   |
| ---------- | ---------------------------------------------------- |
| Trivy      | เร็ว, เก่งเรื่อง CVE ใน image/deps/IaC               |
| SonarQube  | ลึกเรื่อง code smell, bugs, security hotspot ในซอร์ส |

แนะนำลำดับ: **lint/test → Trivy fs → build image → Trivy image → push → deploy**

ตัวอย่าง: [`examples/04-sast-security/`](./examples/04-sast-security/)

---

## 8. Best Practices สรุป

1. **Deploy digest เดิม** ที่ผ่าน staging ไม่ใช่ build ใหม่บน prod
2. **OIDC / short-lived creds** ดีกว่า JSON key ระยะยาวเมื่อทำได้
3. **Approval + audit** สำหรับ production ที่เสี่ยงสูง
4. **Canary/Blue-Green ต้องมี rollback และ metrics** ไม่งั้นเป็นพิธีกรรม
5. **Cache อย่างมีกุญแจ** — key เปลี่ยนเมื่อ lockfile เปลี่ยน
6. **Security scan ต้องทำให้ fail ได้** (`exit-code: 1`) ไม่ใช่แค่รายงานทิ้ง
7. **Least privilege** ของ service account ที่ pipeline ใช้
8. **เอกสาร runbook** — ใคร approve, วิธี rollback, ช่องทาง on-call

---

## ตัวอย่างในระดับนี้

| folder                                                                         | เนื้อหา                                    |
| ------------------------------------------------------------------------------ | ------------------------------------------ |
| [`examples/01-docker-registry-deploy/`](./examples/01-docker-registry-deploy/) | Build/push GHCR + Cloud Run / AWS ตัวอย่าง |
| [`examples/02-blue-green-canary/`](./examples/02-blue-green-canary/)           | Workflow จำลองกลยุทธ์ + approval           |
| [`examples/03-caching-optimization/`](./examples/03-caching-optimization/)     | npm/pip/go cache + docker layer cache      |
| [`examples/04-sast-security/`](./examples/04-sast-security/)                   | Trivy + Sonar โครง pipeline                |

---

**Lab ของระดับนี้ → [`LAB.md`](./LAB.md)**
