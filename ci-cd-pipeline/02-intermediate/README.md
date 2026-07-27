# Level 2 — Intermediate: Advanced Automation & Pipeline as Code

เป้าหมายระดับนี้: ยกระดับจาก “มี CI” เป็น **Pipeline as Code ที่ปลอดภัยและขยายได้**
เจาะ **Jenkinsfile (Declarative)**, **Secrets/Credentials**, **Tests + Artifacts**, และ **Matrix Builds**

---

## สารบัญ

1. [Pipeline as Code คืออะไร](#1-pipeline-as-code-คืออะไร)
2. [Jenkinsfile & Declarative Pipelines](#2-jenkinsfile--declarative-pipelines)
3. [Security & Credentials](#3-security--credentials)
4. [Automated Testing & Artifacts](#4-automated-testing--artifacts)
5. [Matrix Builds (GitHub Actions)](#5-matrix-builds-github-actions)
6. [ออกแบบ Workflow ระดับ Intermediate](#6-ออกแบบ-workflow-ระดับ-intermediate)
7. [Best Practices สรุป](#7-best-practices-สรุป)

---

## 1. Pipeline as Code คืออะไร

**Pipeline as Code** = นิยามขั้นตอน build/test/deploy ไว้ในไฟล์ที่อยู่ใน Git
เช่น `.github/workflows/*.yml` หรือ `Jenkinsfile`

| ได้ประโยชน์   | รายละเอียด                              |
| ------------- | --------------------------------------- |
| Review ได้    | เปลี่ยน pipeline ผ่าน PR เหมือนโค้ดแอป  |
| Rollback ได้  | revert commit แล้ว pipeline กลับของเดิม |
| Reproduce ได้ | instance ใหม่ clone แล้วใช้ชุดเดิม      |
| Audit ได้     | ประวัติใครแก้ stage ไหน ชัดเจน          |

> Freestyle ยังมีที่ทางสำหรับงาน ad-hoc แต่ **งานหลักของทีมควรถูกเก็บเป็นโค้ด**

---

## 2. Jenkinsfile & Declarative Pipelines

Jenkins รองรับ Pipeline 2 แบบหลัก: **Declarative** (อ่านง่าย แนะนำเริ่ม) และ **Scripted** (Groovy ยืดหยุ่นสูง)

### โครง Declarative ขั้นต่ำ

```groovy
pipeline {
 agent any

 environment {
 APP_ENV = 'ci'
 }

 stages {
 stage('Checkout') {
 steps {
 checkout scm
 }
 }
 stage('Install') {
 steps {
 dir('01-beginner/sample-app') {
  sh 'npm install'
 }
 }
 }
 stage('Test') {
 steps {
 dir('01-beginner/sample-app') {
  sh 'npm run lint'
  sh 'npm test'
 }
 }
 }
 }

 post {
 always {
 echo "Finished: ${currentBuild.currentResult}"
 }
 success {
 echo 'All good'
 }
 failure {
 echo 'Investigate console log'
 }
 }
}
```

### คำสำคัญ Declarative

| ท่อน               | ความหมาย                                                          |
| ------------------ | ----------------------------------------------------------------- |
| `agent`            | รันบน node ไหน (`any`, `label 'linux'`, `docker { image '...' }`) |
| `environment`      | ตัวแปรแวดล้อมของ pipeline/stage                                   |
| `stages` / `stage` | ลำดับงานหลัก (โชว์ใน Blue Ocean / Stage View)                     |
| `steps`            | คำสั่งจริง (`sh`, `bat`, `echo`, …)                               |
| `post`             | ทำหลังจบ (`always`, `success`, `failure`, `unstable`, `changed`)  |
| `options`          | timeout, timestamps, disableConcurrentBuilds ฯลฯ                  |
| `parameters`       | รับ input ตอนกด Build with Parameters                             |
| `when`             | เงื่อนไขข้าม stage (เช่นเฉพาะ `main`)                             |

### Agents ที่พบบ่อย

```groovy
agent any

// หรือ
agent {
 docker {
 image 'node:20-alpine'
 args '-u root'
 }
}

// หรือระบุ label ของเครื่องแรง
agent { label 'linux && docker' }
```

ตัวอย่างเต็ม: [`examples/01-jenkinsfile-declarative/`](./examples/01-jenkinsfile-declarative/)

### สร้าง Pipeline Job จาก Jenkinsfile

1. New Item → **Pipeline**
2. Pipeline → Definition: **Pipeline script from SCM**
3. ชี้ Git repo + ระบุ script path `Jenkinsfile`
4. Build — Jenkins จะอ่านไฟล์จาก repo

---

## 3. Security & Credentials

### กฎที่ไม่ต่อรอง

1. **ห้าม** commit API key, token, SSH private key, `.env` ที่มีความลับ
2. ให้ pipeline อ่านจาก **secret store** ของ platform
3. จำกัด scope — secret ใช้ได้เฉพาะ environment/job ที่จำเป็น
4. Rotate ได้ — สมมติว่า leak ได้ ต้องเปลี่ยนเร็ว

### GitHub Secrets

ตั้งค่าที่: **Repo → Settings → Secrets and variables → Actions**

| ชนิด                 | ใช้เมื่อ                                                        |
| -------------------- | --------------------------------------------------------------- |
| Repository secrets   | ใช้ได้ทุก workflow ใน repo                                      |
| Environment secrets  | ผูกกับ environment (`staging`, `production`) + protection rules |
| Organization secrets | แชร์หลาย repo (ระวังสิทธิ์)                                     |

การอ้างใน YAML:

```yaml
jobs:
  deploy:
  runs-on: ubuntu-latest
  environment: staging
  steps:
    - name: Use secret
  env:
    API_TOKEN: ${{ secrets.API_TOKEN }}
    # อย่า echo secret ออกมาทั้งค่า
  run: |
    echo "token length=${#API_TOKEN}"
    curl -H "Authorization: Bearer $API_TOKEN" https://example.invalid/health || true
```

**Masked logs:** GitHub พยายาม mask ค่า secret ใน log แต่ยังห้าม `echo` ออกมาโดยไม่จำเป็น

### Jenkins Credentials Provider

ที่ **Manage Jenkins → Credentials**

ชนิดที่ใช้บ่อย:

| Kind                          | ตัวอย่าง             |
| ----------------------------- | -------------------- |
| Username with password        | Docker Hub login     |
| Secret text                   | API token            |
| SSH Username with private key | Deploy ผ่าน SSH      |
| Secret file                   | kubeconfig, JSON key |

ใน Jenkinsfile:

```groovy
environment {
 REGISTRY_CREDS = credentials('dockerhub-creds') // ได้ _USR / _PSW
}

steps {
 withCredentials([string(credentialsId: 'api-token', variable: 'API_TOKEN')]) {
 sh 'echo "len=${#API_TOKEN}"'
 }
}
```

ตัวอย่างเปรียบเทียบ: [`examples/02-secrets-credentials/`](./examples/02-secrets-credentials/)

---

## 4. Automated Testing & Artifacts

### แทรกคุณภาพเข้าไปใน pipeline

ลำดับที่แนะนำ:

```
checkout → install → lint → unit tests → (build) → archive artifacts
```

ใน GitHub Actions:

```yaml
- name: Test
 working-directory: 01-beginner/sample-app
 run: npm test

- name: Pack artifact
 run: |
 mkdir -p dist
 cp -r 01-beginner/sample-app/src 01-beginner/sample-app/package.json dist/
 zip -r sample-app-${{ github.sha }}.zip dist

- name: Upload artifact
 uses: actions/upload-artifact@v4
 with:
 name: sample-app-dist
 path: sample-app-*.zip
 retention-days: 7
```

ใน Jenkins:

```groovy
stage('Archive') {
 steps {
 dir('01-beginner/sample-app') {
 sh 'zip -r ../sample-app-${BUILD_NUMBER}.zip src package.json'
 }
 archiveArtifacts artifacts: 'sample-app-*.zip', fingerprint: true
 }
}
```

| Artifact เหมาะเก็บ           | ไม่ควรเก็บ                                |
| ---------------------------- | ----------------------------------------- |
| jar/zip/binary ที่ build ได้ | `node_modules/` ทั้งก้อน (ใหญ่เกินจำเป็น) |
| test reports, coverage       | secrets, `.env`                           |
| SBOM / scan reports          | source ที่ Git มีอยู่แล้วโดยไม่จำเป็น     |

ตัวอย่าง: [`examples/03-tests-artifacts/`](./examples/03-tests-artifacts/)

---

## 5. Matrix Builds (GitHub Actions)

**Matrix** = รัน job เดียวกันหลายชุดค่าพร้อมกัน เช่นหลาย version Node หรือหลาย OS

```yaml
jobs:
 test:
 strategy:
 fail-fast: false
 matrix:
 node: [18, 20, 22]
 os: [ubuntu-latest, windows-latest]
 runs-on: ${{ matrix.os }}
 steps:
 - uses: actions/checkout@v4
 - uses: actions/setup-node@v4
 with:
  node-version: ${{ matrix.node }}
 - run: npm install && npm test
 working-directory: 01-beginner/sample-app
```

### เมื่อใดควรใช้ Matrix

| ใช้                            | ไม่จำเป็น                                              |
| ------------------------------ | ------------------------------------------------------ |
| library ต้องรองรับหลาย runtime | แอปภายในที่ lock Node version เดียว                    |
| ต้องยืนยันข้าม OS              | ทุก combination ที่ไม่มีลูกค้าใช้ (สิ้นเปลือง minutes) |

เทคนิคประหยัด:

- `exclude` คู่ที่ไม่ต้องการ
- `fail-fast: true` เมื่ออยากหยุดทั้ง matrix ทันทีที่ตัวหนึ่งพัง (trade-off: เห็นผลทุกช่องช้าลง)
- แยก matrix เฉพาะ job `test` ไม่ต้อง matrix ตอน deploy

ตัวอย่าง: [`examples/04-matrix-builds/`](./examples/04-matrix-builds/)

---

## 6. ออกแบบ Workflow ระดับ Intermediate

แบบที่สมดุลสำหรับทีมเล็ก–กลาง:

```
PR / push
 ├── lint
 ├── test (matrix node 20,22)
 └── build-artifact (needs lint+test)
 └── upload zip

push to main only
 └── (เตรียม deploy — Expert)
```

**Security gates ขั้นกลาง**

- Secrets เฉพาะ environment
- ไม่พิมพ์ secret ใน log
- PR จาก fork: ระวังไม่ให้ได้ secret ของ repo (GitHub มีข้อจำกัดโดยดีไซน์)

---

## 7. Best Practices สรุป

1. **Jenkinsfile ใน repo** — เลิกพึ่ง Freestyle สำหรับงานหลัก
2. **`post` ให้มีประโยชน์** — อย่างน้อย log ผล; ต่อยอดแจ้งเตือนได้
3. **Credentials ID ตั้งชื่อสื่อความหมาย** — `ghcr-push-token` ดีกว่า `cred1`
4. **Artifact มี retention** — กัน storage บloat
5. **Matrix มีขอบเขต** — ทดสอบที่ “สัญญารองรับ” ไม่ใช่ทุก version ในโลก
6. **แยก workflow CI กับ CD** ได้เมื่อไฟล์เริ่มยาว/สิทธิ์ต่างกัน
7. **ใช้ `concurrency`** (Actions) หรือ `disableConcurrentBuilds` (Jenkins) กัน deploy ชนกัน

---

## ตัวอย่างในระดับนี้

| folder                                                                           | เนื้อหา                              |
| -------------------------------------------------------------------------------- | ------------------------------------ |
| [`examples/01-jenkinsfile-declarative/`](./examples/01-jenkinsfile-declarative/) | Jenkinsfile + stages/post/agent      |
| [`examples/02-secrets-credentials/`](./examples/02-secrets-credentials/)         | GitHub Secrets + Jenkins credentials |
| [`examples/03-tests-artifacts/`](./examples/03-tests-artifacts/)                 | lint/test + upload/archive           |
| [`examples/04-matrix-builds/`](./examples/04-matrix-builds/)                     | Node/OS matrix                       |

---

## ขั้นถัดไป

เมื่อทำ Lab ระดับ Intermediate ผ่านแล้ว → [`../03-expert/README.md`](../03-expert/README.md)

**Lab ของระดับนี้ → [`LAB.md`](./LAB.md)**
