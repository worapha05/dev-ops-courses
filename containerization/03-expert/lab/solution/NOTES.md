# NOTES — คำตอบส่วนที่ 7

1. **ทำไม liveness ไม่ควร ping database โดยตรง**
   ถ้า DB ช้า/พลาดชั่วคราว liveness จะล้ม → Kubernetes restart แอปซ้ำ ๆ ทั้งที่ process ยังดี
   ให้ readiness (หรือ dependency health แยก) สะท้อน DB แทน และให้ liveness ตรวจว่า process ค้างจริงหรือไม่

2. **HPA ไม่ขยายทั้งที่โหลดสูง — สาเหตุที่เป็นไปได้**

- ไม่มี metrics-server / metrics ไม่ออก
- ไม่ได้ตั้ง `resources.requests.cpu`
- โหลดไม่กิน CPU (เช่นรอ I/O) แต่ไปดู metric CPU
- ถึง `maxReplicas` แล้ว หรือมี PodDisruption/resource quota ขวาง

3. **Secret ใน K8s vs password manager**
   K8s Secret เป็นกลไก distribute ค่าให้ workload ใน cluster (ต้องคุม RBAC + encryption at rest)
   Password manager เป็นระบบเก็บ/หมุนเวียนความลับของมนุษย์และระบบกลาง — มักเป็นแหล่งความจริง แล้ว sync เข้า cluster ผ่าน External Secrets / operators
