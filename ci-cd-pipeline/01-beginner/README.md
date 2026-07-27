# Level 1 — Beginner: CI/CD Foundations & Basic Workflows

เป้าหมายระดับนี้: ให้คุณเข้าใจ **CI กับ CD คืออะไร** และสร้าง automation ชุดแรกได้จริง
ด้วย **GitHub Actions** และ **Jenkins (Docker + Freestyle)** — ไม่ใช่แค่ copy YAML แต่รู้ว่า workflow ไหลอย่างไร

---

## สารบัญ

1. [Continuous Integration (CI) คืออะไร](#1-continuous-integration-ci-คืออะไร)
2. [Continuous Delivery vs Continuous Deployment](#2-continuous-delivery-vs-continuous-deployment)
3. [Anatomy ของ Automation Pipeline](#3-anatomy-ของ-automation-pipeline)
4. [GitHub Actions — Syntax พื้นฐาน](#4-github-actions--syntax-พื้นฐาน)
5. [Triggers และ Environment Variables](#5-triggers-และ-environment-variables)
6. [Jenkins Core — ติดตั้งด้วย Docker](#6-jenkins-core--ติดตั้งด้วย-docker)
7. [Freestyle Projects และ Build Triggers](#7-freestyle-projects-และ-build-triggers)
8. [GitHub Actions vs Jenkins (มุมเริ่มต้น)](#8-github-actions-vs-jenkins-มุมเริ่มต้น)
9. [Best Practices สรุป](#9-best-practices-สรุป)

---

## 1. Continuous Integration (CI) คืออะไร

**Continuous Integration** คือแนวปฏิบัติที่ทีมรวมโค้ดเข้า branch หลักบ่อย ๆ และให้ **เครื่องอัตโนมัติ** ตรวจคุณภาพทุกครั้งที่มีการเปลี่ยนแปลง

เป้าหมายของ CI:

| เป้าหมาย                 | ความหมายปฏิบัติ                              |
| ------------------------ | -------------------------------------------- |
| ตรวจพบบั๊กเร็ว           | รัน test ภายในไม่กี่นาทีหลัง push            |
| ลด “works on my machine” | build/test ในสภาพแวดล้อมที่กำหนดไว้          |
| ทำให้ merge ปลอดภัยขึ้น  | PR ต้องผ่าน checks ก่อนรวม                   |
| ให้ feedback ที่ชัด      | เห็นว่า fail ที่ lint, unit test, หรือ build |

> **กฎทอง:** CI ที่ดีไม่ใช่ “มีไฟล์ YAML” แต่คือ **ทุก commit ที่สำคัญถูกตรวจอัตโนมัติ** และทีมเชื่อผลของมัน

วงจร CI แบบย่อ:

```
Developer push / open PR
 ↓
Checkout source
 ↓
Install dependencies
 ↓
Lint + Unit tests (+ build ถ้ามี)
 ↓
รายงานสถานะ (pass/fail) กลับไปที่ PR / dashboard
```

ดูแนวคิดเปรียบเทียบ: [`examples/01-ci-cd-concepts/`](./examples/01-ci-cd-concepts/)

---

## 2. Continuous Delivery vs Continuous Deployment

คนมักเรียกรวม ๆ ว่า “CD” แต่ความหมายต่างกันเล็กน้อย:

| แนวคิด                    | ความหมาย                                                       | คนปลายอัตโนมัติ?                                        |
| ------------------------- | -------------------------------------------------------------- | ------------------------------------------------------- |
| **Continuous Delivery**   | โค้ดพร้อมปล่อยได้ตลอด — มี pipeline ถึงขั้น staging/prod-ready | มักมี **manual approval** ก่อน production               |
| **Continuous Deployment** | ทุก change ที่ผ่านเกณฑ์ถูกปล่อย production อัตโนมัติ           | **ไม่มี**ปุ่ม approve (หรือ approve อัตโนมัติตามนโยบาย) |

```
  CI    CD
┌─────────────────────┐ ┌──────────────────────────┐
│ lint → test → build │ → │ package → deploy staging │
└─────────────────────┘ │ ↓ (optional gate) │
    │ deploy production │
    └──────────────────────────┘
```

**เมื่อใดเลือก Delivery แทน Deployment**

- ระบบที่กระทบเงิน/ข้อมูลลูกค้าสูง และต้องการ human sign-off
- ทีมยังไม่มี monitoring / rollback ที่เชื่อถือได้
- ข้อกำหนด compliance ต้องมี approval trail

**เมื่อใด Deployment ทำงานได้ดี**

- แอปมี feature flags, canary, rollback อัตโนมัติ
- test coverage และ observability แข็งแรง
- ทีมปล่อยบ่อย (หลายครั้งต่อวัน) และต้องการลดมือคน

---

## 3. Anatomy ของ Automation Pipeline

ไม่ว่าจะเป็น GitHub Actions หรือ Jenkins โครงสร้างเชิงแนวคิดคล้ายกัน:

```
Trigger (เหตุการณ์)
 └── Pipeline / Workflow (คำจำกัดความทั้งชุด)
 └── Stage / Job (หน่วยงานใหญ่ — อาจขนานได้)
  └── Step (คำสั่งย่อยตามลำดับ)
```

| คำ                  | GitHub Actions                        | Jenkins                        |
| ------------------- | ------------------------------------- | ------------------------------ |
| คำจำกัดความทั้งไฟล์ | Workflow (`.github/workflows/*.yml`)  | Pipeline / Job                 |
| หน่วยงานขนานได้     | Job                                   | Stage (Declarative) / parallel |
| คำสั่งย่อย          | Step                                  | Step                           |
| เครื่องรัน          | Runner (`ubuntu-latest`, self-hosted) | Agent (`any`, label, docker)   |
| ปลั๊กอิน reusable   | Action (`uses:`)                      | Shared Library / Plugin        |

**หลักออกแบบ workflow ระดับ Beginner**

1. **สั้นและชัด** — job แรกควรเป็น lint/test
2. **แยกความรับผิดชอบ** — อย่าผสม “deploy production” ใน workflow เดียวกับทุก PR ถ้ายังไม่พร้อม
3. **ทำให้ล้มเร็ว** — ถ้า test fail ไม่ต้องไป build image

---

## 4. GitHub Actions — Syntax พื้นฐาน

ไฟล์ workflow วางที่:

```text
.github/workflows/<ชื่อ>.yml
```

โครงสร้างขั้นต่ำ:

```yaml
name: CI

on:
 push:
 branches: [main]
 pull_request:
 branches: [main]

jobs:
 test:
 runs-on: ubuntu-latest
 steps:
 - name: Checkout
 uses: actions/checkout@v4

 - name: Setup Node
 uses: actions/setup-node@v4
 with:
  node-version: "20"

 - name: Install
 run: npm ci
 working-directory: 01-beginner/sample-app

 - name: Test
 run: npm test
 working-directory: 01-beginner/sample-app
```

### คำสำคัญที่ต้องจำ

| Keyword             | ทำอะไร                    |
| ------------------- | ------------------------- |
| `name`              | ชื่อที่โชว์ใน UI          |
| `on`                | trigger — เมื่อไหร่ให้รัน |
| `jobs.<id>`         | นิยาม job                 |
| `runs-on`           | เลือก runner              |
| `steps`             | ลำดับงาน                  |
| `uses`              | เรียก Action สำเร็จรูป    |
| `run`               | รันคำสั่ง shell           |
| `with`              | ส่ง input ให้ Action      |
| `env`               | ตัวแปรแวดล้อม             |
| `working-directory` | folder ทำงานของ step      |

ตัวอย่างเต็ม: [`examples/02-github-actions-basics/ci.yml`](./examples/02-github-actions-basics/ci.yml)

### Jobs ขนาน vs ลำดับ

```yaml
jobs:
  lint:
  runs-on: ubuntu-latest
  steps: [...]

  test:
  runs-on: ubuntu-latest
  steps: [...]

  build:
  needs: [lint, test] # รอให้ lint และ test ผ่านก่อน
  runs-on: ubuntu-latest
  steps: [...]
```

- ไม่ใส่ `needs` → jobs รันขนาน (เร็วขึ้น แต่ใช้นาที runner มากขึ้น)
- ใส่ `needs` → สร้างลำดับ dependency กราฟ

---

## 5. Triggers และ Environment Variables

### Triggers ที่ใช้บ่อย

```yaml
on:
  push:
  branches: [main, develop]
  paths:
    - '01-beginner/sample-app/**'
    - '.github/workflows/**'
  pull_request:
  types: [opened, synchronize, reopened]
  workflow_dispatch: # กดรันมือจาก UI
  schedule:
    - cron: '0 2 * * 1' # ทุกวันจันทร์ 02:00 UTC
```

| Trigger             | ใช้เมื่อ                             |
| ------------------- | ------------------------------------ |
| `push`              | รวมโค้ดแล้วอยากรัน CI / deploy       |
| `pull_request`      | ตรวจก่อน merge                       |
| `workflow_dispatch` | งานที่ต้องกดมือ (เช่น hotfix deploy) |
| `schedule`          | nightly build, dependency audit      |

### Environment Variables

มี 3 ระดับที่พบบ่อย:

```yaml
env: # ระดับ workflow — ใช้ได้ทุก job
  APP_NAME: sample-app

jobs:
  build:
  runs-on: ubuntu-latest
  env: # ระดับ job
  NODE_ENV: test
  steps:
    - name: Print context
  env: # ระดับ step
    GREETING: hello
  run: |
    echo "app=$APP_NAME"
    echo "env=$NODE_ENV"
    echo "greet=$GREETING"
    echo "sha=${{ github.sha }}"
    echo "ref=${{ github.ref }}"
```

**Context ที่ใช้บ่อย**

| Expression                 | ความหมาย                                 |
| -------------------------- | ---------------------------------------- |
| `${{ github.sha }}`        | commit SHA                               |
| `${{ github.ref }}`        | ref ที่ trigger (เช่น `refs/heads/main`) |
| `${{ github.actor }}`      | ผู้ที่ trigger                           |
| `${{ github.repository }}` | `owner/repo`                             |
| `${{ runner.os }}`         | OS ของ runner                            |

> **คำเตือน Beginner:** อย่าใส่ API key ใน `env:` ของ YAML ที่ commit ขึ้น Git
> ระดับ Intermediate จะเรียน GitHub Secrets / Jenkins Credentials

ตัวอย่าง: [`examples/03-github-actions-env-vars/`](./examples/03-github-actions-env-vars/)

---

## 6. Jenkins Core — ติดตั้งด้วย Docker

Jenkins เป็น automation server แบบ self-hosted ที่นิยมในองค์กร
จุดแข็ง: ยืดหยุ่น, plugin เยอะ, ควบคุม infrastructure เองได้
จุดที่ต้องระวัง: ดูแลเครื่อง/update/security ของ Jenkins เอง

### ติดตั้งเร็วด้วย Docker Compose (ของ bootcamp)

จาก root ของ bootcamp:

```bash
cd cicd-pipeline-bootcamp
docker compose up -d

# รอ ~30–60 วินาที แล้วเปิด http://localhost:8080
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

ขั้นตอน Setup Wizard โดยสรุป:

1. วาง **Initial Admin Password**
2. ติดตั้ง **Suggested plugins** (เพียงพอสำหรับ Beginner)
3. สร้างผู้ใช้ admin
4. ยืนยัน Jenkins URL (`http://localhost:8080/`)

รายละเอียดและ script ช่วย: [`examples/04-jenkins-docker-setup/`](./examples/04-jenkins-docker-setup/)

### Dashboard ที่ควรรู้จัก

| มุม UI             | ใช้ทำอะไร                             |
| ------------------ | ------------------------------------- |
| **New Item**       | สร้าง Freestyle / Pipeline            |
| **Manage Jenkins** | plugins, credentials, nodes, security |
| **Build History**  | ดูผลรันล่าสุด                         |
| **My Views**       | กรอง job ที่สนใจ                      |

---

## 7. Freestyle Projects และ Build Triggers

**Freestyle Project** คือ job แบบคลิกตั้งค่าใน UI — เหมาะเริ่มต้นเรียนรู้
(ระดับ Intermediate จะย้ายไป **Jenkinsfile / Pipeline as Code**)

### สร้าง Freestyle ง่าย ๆ

1. **New Item** → ชื่อ `sample-freestyle` → **Freestyle project**
2. **Source Code Management** → Git → ใส่ URL ของ repo (หรือใช้ local สำหรับทดลอง)
3. **Build Triggers**

- `GitHub hook trigger for GITScm polling` (เมื่อตั้ง webhook)
- หรือ `Poll SCM` เช่น `H/5 * * * *` (เช็คทุก ~5 นาที — ใช้เรียนได้ แต่ production นิยม webhook)

4. **Build Steps** → Execute shell:

```bash
cd sample-app
npm install
npm test
```

5. Save → **Build Now**

### Build Triggers แบบย่อ

| Trigger                 | ข้อดี          | ข้อควรระวัง                 |
| ----------------------- | -------------- | --------------------------- |
| Manual (Build Now)      | ควบคุมได้      | ไม่ต่อเนื่อง                |
| Poll SCM                | ตั้งง่าย       | ช้า/สิ้นเปลืองกว่า webhook  |
| Webhook (GitHub/GitLab) | ใกล้ real-time | ต้องเปิด network + secret   |
| Timer                   | งานประจำ       | อย่าใช้แทน CI ของทุก commit |

> Freestyle ดีสำหรับเรียนรู้ UI แต่ **อย่าหยุดที่ Freestyle** ในงานจริง
> เพราะ config อยู่ใน Jenkins ไม่ได้อยู่ใน Git — review/rollback ยาก

---

## 8. GitHub Actions vs Jenkins (มุมเริ่มต้น)

| มิติ            | GitHub Actions                           | Jenkins                                      |
| --------------- | ---------------------------------------- | -------------------------------------------- |
| Hosting         | GitHub-hosted runners (หรือ self-hosted) | คุณดูแลเอง (VM/K8s/Docker)                   |
| Config          | YAML ใน repo                             | UI (Freestyle) หรือ Jenkinsfile ใน repo      |
| ราคา/โควต้า     | มี minutes จำกัดตามแผน                   | ค่า infra + เวลาดูแล                         |
| Ecosystem       | Marketplace Actions                      | Plugins + Shared Libraries                   |
| เหมาะเริ่มเมื่อ | โค้ดอยู่บน GitHub อยู่แล้ว               | องค์กรต้องการควบคุมเต็ม / multi-repo ซับซ้อน |

หลายทีมใช้ **ทั้งคู่**: Actions สำหรับ CI ของแอปบน GitHub, Jenkins สำหรับ deploy ภายในหรือ legacy systems

---

## 9. Best Practices สรุป

1. **CI ทุก PR** — อย่างน้อย lint + unit test
2. **ตั้งชื่อ workflow/job ให้สื่อความหมาย** — `CI`, `test`, `lint` ดีกว่า `workflow1`
3. **Pin version Action** — ใช้ `@v4` หรือ pin SHA ในงานจริงที่เข้มงวด
4. **อย่า commit secrets**
5. **Fail fast** — งานถูกและเร็วมาก่อน งานแพงทีหลัง
6. **เก็บ pipeline ใน Git** ให้เร็วที่สุด ( Intermediate จะเจาะ Jenkinsfile )
7. **เอกสารสั้น ๆ ใน README ของ repo** ว่าต้องมี secret/ตัวแปรอะไรบ้าง
8. **แยก `push` กับ `pull_request`** เมื่อพฤติกรรมต่างกัน (เช่น deploy เฉพาะ `main`)

---

## ตัวอย่างในระดับนี้

| folder                                                                           | เนื้อหา                             |
| -------------------------------------------------------------------------------- | ----------------------------------- |
| [`examples/01-ci-cd-concepts/`](./examples/01-ci-cd-concepts/)                   | แผนภาพและ checklist ออกแบบ pipeline |
| [`examples/02-github-actions-basics/`](./examples/02-github-actions-basics/)     | Workflow CI พื้นฐาน                 |
| [`examples/03-github-actions-env-vars/`](./examples/03-github-actions-env-vars/) | Triggers + env + contexts           |
| [`examples/04-jenkins-docker-setup/`](./examples/04-jenkins-docker-setup/)       | ติดตั้ง Jenkins + แนว Freestyle     |

---

## ขั้นถัดไป

เมื่อทำ Lab ระดับ Beginner ผ่านแล้ว → [`../02-intermediate/README.md`](../02-intermediate/README.md)

**Lab ของระดับนี้ → [`LAB.md`](./LAB.md)**
