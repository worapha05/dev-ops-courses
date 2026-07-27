# 05 — Security Hardening

ไฟล์ใน folder นี้:

- `deployment-secure.yaml` — securityContext แบบ non-root / drop caps
- `networkpolicy.yaml` — จำกัด ingress เข้า backend จาก frontend เท่านั้น

```bash
kubectl apply -f deployment-secure.yaml
kubectl apply -f networkpolicy.yaml
```

หมายเหตุ: NetworkPolicy มีผลเมื่อ CNI ของ cluster รองรับ
บน Minikube อาจต้องใช้ CNI อย่าง Calico หรือทดสอบบน Kind + Calico
