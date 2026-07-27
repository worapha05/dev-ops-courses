# 04 — Jenkins ด้วย Docker + Freestyle

## สตาร์ท Jenkins

จาก root ของ bootcamp:

```bash
docker compose up -d
docker compose logs -f jenkins # รอจนพร้อม
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

เปิด `http://localhost:8080` แล้วทำ Setup Wizard

## สร้าง Freestyle Project (สรุป)

ดูขั้นตอนละเอียดใน [`freestyle-guide.md`](./freestyle-guide.md)

script build ตัวอย่าง: [`build.sh`](./build.sh)

## หยุด / ลบ

```bash
docker compose down    # หยุด แต่เก็บ volume
docker compose down -v # ลบข้อมูล Jenkins ด้วย (ระวัง)
```
