# เฉลยคำถามคิด — Lab Intermediate

## 1. fail-fast true vs false

- `true`: ช่องหนึ่ง fail → ยกเลิกช่องอื่นเร็ว ประหยัด minutes แต่ทีมอาจไม่เห็นว่าอีก OS/version พังด้วยหรือไม่
- `false`: รันครบทุกช่อง ได้ภาพรวมปัญหา แต่ใช้เวลานาที runner มากกว่า

## 2. จำกัด artifact บน PR

- upload เฉพาะ `push` ไป `main` (เหมือนเฉลย `package` job)
- ตั้ง `retention-days` สั้นลง
- อย่าเก็บ `node_modules`

## 3. Environment vs repository secrets

- Repository secrets: ใช้ได้จาก job ทั่วไปใน repo
- Environment secrets: ผูกกับ environment + ใส่ protection rules (required reviewers, wait timer, limited branches) ได้ — เหมาะของ production
