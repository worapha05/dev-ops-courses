# 01 — Container Concepts

เอกสารนี้สรุปภาพเปรียบเทียบสำหรับอ้างอิงขณะเรียนทฤษฎี

## Container vs VM (ย่อ)

```
VM:
Hypervisor
 └── Guest OS + Libs + App (หนัก, แยกเคอร์เนล)

Container:
Host OS (shared kernel)
 └── Libs + App  (เบา, แยก namespace)
```

## คำสามคำที่ต้องแยกให้ขาด

| คำ        | คืออะไร                 | ตัวอย่าง                  |
| --------- | ----------------------- | ------------------------- |
| Image     | แม่แบบ immutable        | `nginx:1.27-alpine`       |
| Container | process ที่รันจาก image | `docker run -d nginx:...` |
| Registry  | ที่เก็บ image           | Docker Hub, GHCR          |

## Checklist ความเข้าใจ

- [ ] อธิบายได้ว่าทำไม container สตาร์ทเร็วกว่า VM
- [ ] บอกได้ว่าข้อมูลใน writable layer หายเมื่อลบ container
- [ ] รู้ว่า registry ใช้ตอนไหนในวงจร build → ship → run
