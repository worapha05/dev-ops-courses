# เฉลย Lab Beginner — CafeStack

โครงสร้างเฉลยย่อ (ครบตามเกณฑ์ Lab):

```text
lab/solution/
├── README.md
├── NOTES.md
├── docker-compose.yml
├── backend/
│ ├── Dockerfile
│ ├── package.json
│ ├── init.sql
│ └── src/server.js
└── frontend/
 ├── Dockerfile
 ├── nginx.conf
 └── public/index.html
```

## วิธีรันเฉลย

```bash
cd 01-beginner/lab/solution
docker compose up --build
```

- UI: http://localhost:8081
- API health: http://localhost:3001/health

> porthost เป็น `8081` / `3001` เพื่อไม่ชนกับ [`sample-app`](../../sample-app/) (`8080` / `3000`)
