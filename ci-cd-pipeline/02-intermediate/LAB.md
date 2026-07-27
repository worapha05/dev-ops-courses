# Lab ระดับ Intermediate — Pipeline as Code ของ “ShopFlow”

## เป้าหมาย

ยกระดับ CI ของ platform ร้านค้าออนไลน์จำลอง **ShopFlow** ให้เป็น Pipeline as Code ที่:

- มี **Declarative Jenkinsfile** ครบ stages + post
- ใช้ **GitHub Secrets / Jenkins Credentials** อย่างปลอดภัย
- รัน **lint + test** แล้ว **archive artifact**
- มี **matrix** ทดสอบหลาย version Node บน GitHub Actions

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

ShopFlow เคยใช้ Freestyle job ที่ Senior คนเดียวตั้งไว้บนเครื่อง VM
วันหนึ่ง VM พัง — ไม่มีใครรู้ว่า build step คืออะไรบ้าง และเคยมีคนเผลอ commit API token ลง Jenkinsfile เก่า

Head of Engineering ขอให้คุณ:

1. ย้ายทุกอย่างเป็นโค้ดใน Git
2. ห้ามมี secret ใน repo
3. เก็บ zip ของ `sample-app` ทุก build ที่ผ่านบน `main`
4. ยืนยันว่าแอปผ่านบน Node 20 และ 22

---

## โจทย์

### ส่วนที่ 1 — Declarative Jenkinsfile

สร้าง `Jenkinsfile` ที่ root (หรือตาม path ที่ job ชี้) โดยมีอย่างน้อย:

| Stage    | งาน                               |
| -------- | --------------------------------- |
| Checkout | `checkout scm`                    |
| Install  | `npm install` ใน `sample-app`     |
| Lint     | `npm run lint`                    |
| Test     | `npm test`                        |
| Archive  | สร้าง zip แล้ว `archiveArtifacts` |

เพิ่ม:

- `options { timestamps(); timeout(...) }`
- `post { always / success / failure }`
- แนะนำใช้ `agent { docker { image 'node:20-bookworm' } }` ถ้าสภาพแวดล้อมคุณรองรับ

### ส่วนที่ 2 — GitHub Actions + Matrix + Artifact

สร้าง `.github/workflows/shopflow-ci.yml`:

1. Trigger: `push` + `pull_request` ไป `main`
2. Job `test` ใช้ matrix `node: [20, 22]` บน `ubuntu-latest`
3. Job `package` ทำงานเมื่อ `needs: [test]` สำเร็จ และ **เฉพาะตอน push ไป main** (`if:`)
4. `package` สร้าง zip และ `actions/upload-artifact@v4` retention 7 วัน
5. อ่าน secret `SHOPFLOW_SLACK_WEBHOOK` (หรือชื่อที่คุณตั้ง) แบบปลอดภัยใน job `notify` แบบ optional — ถ้าไม่มี secret ให้ skip ด้วยเงื่อนไข ไม่ทำให้ทั้ง workflow แดงโดยไม่จำเป็น

> อย่างน้อยต้องมีตัวอย่างการใช้ `${{ secrets.XXX }}` ในไฟล์เฉลย/ของคุณเอง โดยไม่ echo ค่า secret

### ส่วนที่ 3 — Credentials บน Jenkins

1. สร้าง Secret text ใน Jenkins id: `shopflow-demo-token`
2. ใน Jenkinsfile (stage แยกหรือใน post) ใช้ `withCredentials` แล้วพิมพ์เฉพาะ `token_length`
3. เขียนใน `SECURITY.md` สั้น ๆ ว่าทำไมห้าม commit token

### ส่วนที่ 4 — คำถามคิด

1. `fail-fast: true` กับ `false` ใน matrix ต่างกันอย่างไรต่อ feedback ของทีม?
2. ทำไม upload artifact ทุก PR อาจแพง/รก — จะจำกัดอย่างไร?
3. Environment secrets ต่างจาก repository secrets อย่างไร?

---

## เกณฑ์ผ่าน

- [ ] Jenkinsfile Declarative รัน stages จน archive ได้
- [ ] GitHub workflow มี matrix Node 20/22
- [ ] มีการ upload/archive artifact
- [ ] มีการใช้ credentials/secrets โดยไม่พิมพ์ค่าดิบ
- [ ] มีบันทึกความปลอดภัยสั้น ๆ

---

## คำใบ้

- [`examples/01-jenkinsfile-declarative/Jenkinsfile`](./examples/01-jenkinsfile-declarative/Jenkinsfile)
- [`examples/03-tests-artifacts/`](./examples/03-tests-artifacts/)
- [`examples/04-matrix-builds/matrix-ci.yml`](./examples/04-matrix-builds/matrix-ci.yml)
- Secrets: [`examples/02-secrets-credentials/`](./examples/02-secrets-credentials/)

---

## เฉลย

[`lab/solution/`](./lab/solution/)
