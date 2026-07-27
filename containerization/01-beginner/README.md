# Level 1 — Beginner: Docker Foundations & Local Operations

เป้าหมายระดับนี้: ให้คุณเข้าใจ **Containerization คืออะไร** และใช้งาน **Docker** ได้จริงบนเครื่องท้องถิ่น
ตั้งแต่แนวคิด Image/Container/Registry → CLI → Volumes/Networks → **Docker Compose** สำหรับแอปหลายบริการ

---

## สารบัญ

1. [Containerization Concepts](#1-containerization-concepts)
2. [Images, Containers และ Registries](#2-images-containers-และ-registries)
3. [Docker CLI Core](#3-docker-cli-core)
4. [Storage — Volumes และ Bind Mounts](#4-storage--volumes-และ-bind-mounts)
5. [Networks — เชื่อม container เข้าด้วยกัน](#5-networks--เชื่อม-container-เข้าด้วยกัน)
6. [Dockerfile พื้นฐาน](#6-dockerfile-พื้นฐาน)
7. [Docker Compose — Multi-container บนเครื่องเดียว](#7-docker-compose--multi-container-บนเครื่องเดียว)
8. [สถาปัตยกรรมเบื้องหลัง (Local)](#8-สถาปัตยกรรมเบื้องหลัง-local)
9. [Best Practices สรุป](#9-best-practices-สรุป)

---

## 1. Containerization Concepts

### Container คืออะไร

**Container** คือหน่วยรันแอปที่แพ็ก **โค้ด + runtime + dependencies** ไว้ด้วยกัน
แชร์เคอร์เนลของ host แต่แยก process tree, filesystem view, network namespace และ resource limit

```
┌──────────────── Host OS (Shared Kernel) ────────────────┐
│ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│ │ App A │ │ App B │ │ App C │ ← containers │
│ │ libs │ │ libs │ │ libs │  │
│ └──────────┘ └──────────┘ └──────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Container vs Virtual Machine

| มิติ        | Container                 | Virtual Machine                                     |
| ----------- | ------------------------- | --------------------------------------------------- |
| Isolation   | Process / namespace level | Hardware virtualization + guest OS                  |
| ขนาด        | MB–ร้อย MB                | GB ขึ้นไป                                           |
| เวลาสตาร์ท  | วินาที                    | นาที                                                |
| ความหนาแน่น | รันบน host เดียวได้มาก    | น้อยกว่าต่อเครื่อง                                  |
| Use case    | แอป / microservice        | OS ต่างกันทั้งระบบ, legacy ที่ต้องการ guest OS เต็ม |

> **กฎทอง:** Container ไม่ใช่ “VM ขนาดเล็ก” — มันคือ **process ที่ถูกแพ็กและจำกัดขอบเขต**
> ถ้าต้องการเคอร์เนลคนละตัว หรือ Windows guest บน Linux host แบบเต็ม ๆ ให้คิดถึง VM

### ทำไมองค์กรใช้ Container

| เหตุผล                       | ความหมายปฏิบัติ                                  |
| ---------------------------- | ------------------------------------------------ |
| Consistency                  | Dev / CI / Prod ใช้ image ชุดเดียวกัน            |
| ความเร็ว deploy              | Build ครั้งเดียว รันที่ไหนก็ได้ที่รองรับ runtime |
| Density                      | ใช้เครื่องคุ้มกว่า VM ต่อแอป                     |
| Foundation ของ orchestration | Kubernetes จัดตารางงานบนหน่วย container          |

ดูภาพเปรียบเทียบ: [`examples/01-container-concepts/`](./examples/01-container-concepts/)

---

## 2. Images, Containers และ Registries

### Image

**Image** = แม่แบบอ่านอย่างเดียว (immutable) ที่ประกอบด้วย layers ของ filesystem
สร้างจาก `Dockerfile` หรือดึงจาก registry

```
Layer N ← คำสั่งสุดท้ายใน Dockerfile (เช่น CMD)
 …
Layer 2 ← COPY / RUN
Layer 1 ← FROM base image
```

แต่ละ layer เป็น cache ได้ — เรียงคำสั่งให้ส่วนที่เปลี่ยนบ่อยอยู่ด้านล่างสุดของไฟล์จะ rebuild เร็วขึ้น

### Container

**Container** = instance ที่รันจาก image
มี writable layer ชั่วคราวทับบน image — เมื่อลบ container ข้อมูลใน layer นี้หาย (ยกเว้น mount volume)

```
docker run nginx:1.27-alpine
 │
 ▼
สร้าง container จาก image → รัน process หลัก (PID 1 ใน namespace)
```

### Registry

**Registry** = ที่เก็บและแจกจ่าย image (Docker Hub, GHCR, Artifact Registry, ECR)

```
build → tag → push registry → pull บนเครื่อง/cluster อื่น → run
```

| คำสั่งเกี่ยวข้อง | ความหมาย                     |
| ---------------- | ---------------------------- |
| `docker pull`    | ดึง image                    |
| `docker push`    | ส่ง image ขึ้น registry      |
| `docker tag`     | ตั้งชื่อ `registry/repo:tag` |
| `docker login`   | ยืนยันตัวตนกับ registry      |

> หลีกเลี่ยงการพึ่ง `:latest` เป็นแหล่งความจริง — ใช้ tag ชัดเจน เช่น `1.2.0` หรือ `sha-abc1234`

---

## 3. Docker CLI Core

คำสั่งที่ต้องคล่องก่อนไป Compose / Kubernetes:

### Lifecycle พื้นฐาน

```bash
# รัน container (interactive + ลบเมื่อออก)
docker run --rm -it alpine:3.20 sh

# รัน background พร้อม map port
docker run -d --name web -p 8080:80 nginx:1.27-alpine

# ดูสถานะ
docker ps    # กำลังรัน
docker ps -a # รวมที่หยุดแล้ว

# ดู log / เข้าไปใน container
docker logs -f web
docker exec -it web sh

# หยุดและลบ
docker stop web
docker rm web

# จัดการ image
docker images
docker rmi nginx:1.27-alpine

# build จาก Dockerfile
docker build -t myapp:dev .
```

### ตารางคำสั่งสำคัญ

| คำสั่ง                  | ใช้เมื่อ                              |
| ----------------------- | ------------------------------------- |
| `docker run`            | สร้างและสตาร์ท container จาก image    |
| `docker build`          | สร้าง image จาก Dockerfile            |
| `docker ps`             | ตรวจว่าอะไรกำลังรัน                   |
| `docker stop` / `start` | หยุด/เปิดใหม่โดยไม่ลบ                 |
| `docker rm` / `rmi`     | ลบ container / image                  |
| `docker logs`           | ดีบักแอปใน container                  |
| `docker exec`           | รันคำสั่งเพิ่มใน container ที่รันอยู่ |
| `docker inspect`        | ดู JSON metadata (IP, mounts, env)    |

ตัวอย่าง cheat sheet: [`examples/02-docker-cli/`](./examples/02-docker-cli/)

### สิ่งที่มักสับสน

| สถานการณ์             | สิ่งที่ควรทำ                                  |
| --------------------- | --------------------------------------------- |
| แก้โค้ดแล้วไม่เห็นผล  | rebuild image หรือ mount source เข้าไปตอน dev |
| Port ชน               | เปลี่ยนฝั่ง host ใน `-p HOST:CONTAINER`       |
| Container ออกทันที    | ดู `docker logs` — process หลักจบหรือ crash   |
| ลบไม่ได้เพราะกำลังรัน | `docker stop` ก่อน แล้วค่อย `rm`              |

---

## 4. Storage — Volumes และ Bind Mounts

Filesystem ใน container **ชั่วคราว** — เหมาะกับโค้ด/cache ที่ recreate ได้
ข้อมูลที่ต้องคงอยู่ (DB, upload) ต้องออกนอก writable layer

### เปรียบเทียบ

| แบบ              | คำสั่งตัวอย่าง                       | ข้อดี                                 | ข้อควรระวัง                              |
| ---------------- | ------------------------------------ | ------------------------------------- | ---------------------------------------- |
| **Named Volume** | `-v pgdata:/var/lib/postgresql/data` | จัดการโดย Docker, ย้ายเครื่องง่ายกว่า | ดู path จริงต้อง `docker volume inspect` |
| **Bind Mount**   | `-v "$(pwd)/data:/data"`             | แก้ไฟล์บน host เห็นทันที (dev)        | path ผูกเครื่อง, สิทธิ์ UID/GID          |
| **tmpfs**        | `--tmpfs /tmp`                       | เร็ว อยู่ใน RAM                       | หายเมื่อหยุด container                   |

### หลักออกแบบ Storage

```
Ephemeral (ใน container) Persistent (นอก container)
───────────────────── ──────────────────────────
โค้ดที่ bake ใน image  database files
dependency ที่ติดตั้งแล้ว user uploads
temp / cache   certificates ที่ rotate นอก image
```

> **อย่า** เก็บข้อมูลธุรกิจสำคัญไว้แค่ใน container filesystem
> **อย่า** bake secret ลง image layer — ใช้ env ตอนรัน หรือ secret store

ตัวอย่าง: [`examples/03-volumes-networks/`](./examples/03-volumes-networks/)

---

## 5. Networks — เชื่อม container เข้าด้วยกัน

Docker สร้าง network แยกได้หลายชนิด ที่ใช้บ่อยบนเครื่อง local คือ **bridge**

```
┌──────────── docker network: app-net ────────────┐
│ frontend (ชื่อ DNS: frontend)   │
│ │ HTTP     │
│ ▼      │
│ backend ──────► db    │
└──────────────────────────────────────────────────┘
  ▲
  │ publish -p 8080:80 (เข้าจาก host)
```

### ข้อควรรู้

| หัวข้อ                  | รายละเอียด                                                                          |
| ----------------------- | ----------------------------------------------------------------------------------- |
| DNS ใน network เดียวกัน | เรียก service ด้วย **ชื่อ container/service** ไม่ต้องจำ IP                          |
| Port publish            | `-p` เปิดให้ host/ภายนอก — ภายใน network พูดกันที่ port ของ container ได้เลย        |
| แยก network             | frontend กับ db ไม่ควรอยู่ใน “flat network” เดียวกันถ้าไม่จำเป็น (defense in depth) |

```bash
docker network create app-net
docker run -d --name db --network app-net postgres:16-alpine
docker run -d --name api --network app-net -e DATABASE_URL=... myapi:dev
```

---

## 6. Dockerfile พื้นฐาน

`Dockerfile` คือสูตรสร้าง image แบบประกาศขั้นตอน

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY src ./src
EXPOSE 3000
USER node
CMD ["node", "src/server.js"]
```

| คำสั่ง               | ความหมาย                                          |
| -------------------- | ------------------------------------------------- |
| `FROM`               | base image                                        |
| `WORKDIR`            | ตั้ง working directory                            |
| `COPY` / `ADD`       | ใส่ไฟล์เข้า image (`COPY` ชัดเจนกว่า ใช้เป็นหลัก) |
| `RUN`                | รันตอน **build**                                  |
| `ENV`                | ตัวแปรสภาพแวดล้อมใน image                         |
| `EXPOSE`             | เอกสารว่า port ไหน (ไม่ได้เปิด firewall ให้เอง)   |
| `USER`               | สลับ user (อย่ารัน root ถ้าไม่จำเป็น)             |
| `CMD` / `ENTRYPOINT` | process หลักตอน `docker run`                      |

### ลำดับ layer เพื่อ cache

1. คัดลอกไฟล์ dependency ก่อน (`package.json`, `go.mod`, …)
2. `RUN install`
3. คัดลอก source ท้ายสุด

แบบนี้แก้โค้ดนิดเดียวจะไม่ต้องติดตั้ง dependency ใหม่ทุกครั้ง

---

## 7. Docker Compose — Multi-container บนเครื่องเดียว

เมื่อมี frontend + backend + database การจำ `docker run` ยาว ๆ ไม่คุ้ม
**Docker Compose** รวมนิยามบริการ เครือข่าย และ volume ไว้ในไฟล์เดียว

```bash
docker compose up --build
docker compose ps
docker compose logs -f backend
docker compose down    # หยุดและลบ containers ของ project
docker compose down -v # รวมลบ named volumes (ระวังข้อมูลหาย)
```

โครงย่อ:

```yaml
services:
  frontend:
  build: ./frontend
  ports: ['8080:80']
  depends_on:
  backend:
  condition: service_healthy
  backend:
  build: ./backend
  environment:
  DATABASE_URL: postgres://user:pass@db:5432/app
  db:
  image: postgres:16-alpine
  volumes:
    - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

### หลักออกแบบ Compose สำหรับ local

| หลัก                     | ปฏิบัติ                                                |
| ------------------------ | ------------------------------------------------------ |
| หนึ่ง project หนึ่งไฟล์  | `docker-compose.yml` ที่ root ของแอป                   |
| Healthcheck + depends_on | รอ DB พร้อมก่อนสตาร์ท API                              |
| ชื่อ service = DNS       | backend เรียก `db:5432` ได้เลย                         |
| แยก override             | ใช้ `compose.override.yml` สำหรับ dev mount ถ้าต้องการ |
| ไม่ใส่ secret จริงใน Git | ใช้ `.env` ที่ gitignore                               |

ตัวอย่างครบ: [`examples/04-docker-compose/`](./examples/04-docker-compose/)
และชุดจริงใน [`./sample-app/`](./sample-app/)

---

## 8. สถาปัตยกรรมเบื้องหลัง (Local)

บน Linux โดยทั่วไป:

```
CLI (docker) → Dockerd (API) → containerd → runc → Linux namespaces/cgroups
```

| ชั้น              | บทบาท                                             |
| ----------------- | ------------------------------------------------- |
| CLI               | ส่งคำสั่งจากผู้ใช้                                |
| Engine (dockerd)  | API, image build, orchestration ระดับเครื่อง      |
| containerd / runc | จัดการ lifecycle และสร้าง container จริง          |
| kernel            | namespaces (pid, net, mnt, …) + cgroups (CPU/RAM) |

บน Docker Desktop (WSL2/macOS) จะมี Linux VM บางส่วนช่วยรัน engine — แนวคิดการใช้งาน CLI เหมือนกัน

### ผลกระทบต่อการออกแบบ

- Container แชร์เคอร์เนล → อย่าสมมติว่า “แยกขาดระดับ hypervisor”
- Resource limit (`--memory`, `--cpus`) สำคัญเมื่อรันหลายบริการบนเครื่องเดียว
- Network namespace ทำให้ “localhost ใน container” ≠ “localhost บน host”

---

## 9. Best Practices สรุป

1. **เข้าใจ Image vs Container** ก่อนท่องจำคำสั่ง
2. **Tag ชัดเจน** — ไม่ deploy ด้วย `:latest` เป็นหลัก
3. **ข้อมูลถาวรใช้ Volume** — DB ต้องมี named volume หรือ managed storage
4. **Network ตามความจำเป็น** — service พูดกันด้วยชื่อ ไม่ hardcode IP
5. **Dockerfile เรียงเพื่อ cache** และรัน non-root เมื่อทำได้
6. **Compose สำหรับ local multi-service** — อย่าคัดลอก compose ไปเป็น production orchestration ตรง ๆ
7. **ตรวจด้วย logs/exec/inspect** ก่อนโทษว่า “Docker พัง”
8. **อย่าใส่ secret ใน image หรือ commit `.env`**

---

## ไฟล์ตัวอย่างในระดับนี้

| folder                                                                 | เนื้อหา                           |
| ---------------------------------------------------------------------- | --------------------------------- |
| [`examples/01-container-concepts/`](./examples/01-container-concepts/) | แผนภาพเปรียบเทียบ Container vs VM |
| [`examples/02-docker-cli/`](./examples/02-docker-cli/)                 | Script ฝึกคำสั่งพื้นฐาน           |
| [`examples/03-volumes-networks/`](./examples/03-volumes-networks/)     | Volume + custom bridge network    |
| [`examples/04-docker-compose/`](./examples/04-docker-compose/)         | Compose ย่อสำหรับ API + Redis     |

เมื่อพร้อมแล้วไปที่ [`LAB.md`](./LAB.md) — สถานการณ์แพ็คแอป Full-stack ของทีม **CafeStack**
