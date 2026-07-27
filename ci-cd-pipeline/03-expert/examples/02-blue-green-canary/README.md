# 02 — Blue-Green, Canary & Approval

| ไฟล์                                             | เนื้อหา                                                 |
| ------------------------------------------------ | ------------------------------------------------------- |
| [`blue-green.yml`](./blue-green.yml)             | จำลอง deploy green → smoke → switch → optional rollback |
| [`canary.yml`](./canary.yml)                     | จำลอง canary 5% → evaluate → promote                    |
| [`Jenkinsfile.approval`](./Jenkinsfile.approval) | `input` gate ก่อน production                            |

ไฟล์เหล่านี้เป็น **orchestration จำลอง** (ใช้ echo/curl แทน cloud API จริง)
เพื่อให้ฝึกออกแบบ stage และ approval ก่อนผูก vendor
