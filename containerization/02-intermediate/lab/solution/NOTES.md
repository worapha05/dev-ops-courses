# NOTES — คำตอบส่วนที่ 6

1. **ทำไมต้องมี Service**
   Pod IP เปลี่ยนทุกครั้งที่ recreate และมีหลาย replica
   Service ให้ DNS/VIP คงที่และกระจาย traffic ไป Pod ที่ match label

2. **ClusterIP vs NodePort (มุม security demo)**
   ClusterIP เข้าได้แค่ใน cluster — ลดการเปิด port ออก host
   NodePort เปิด port บน Node เพื่อ demo จากภายนอก ควรใช้เฉพาะช่วงทดสอบและจำกัด firewall ในสภาพแวดล้อมจริง

3. **imagePullPolicy: Always กับ local image**
   kubelet จะพยายามดึงจาก registry ทุกครั้งที่สร้าง Pod
   ถ้าไม่มี image บน registry จะได้ `ErrImagePull` / `ImagePullBackOff`
   สำหรับ image ที่ load เข้า node ท้องถิ่น ใช้ `IfNotPresent` หรือ `Never`
