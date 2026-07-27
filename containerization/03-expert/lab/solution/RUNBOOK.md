# RUNBOOK — AetherBank Troubleshooting

## อาการ: Pod Running แต่ไม่มี Endpoints

**สัญญาณ:** `kubectl get endpoints ledger-api` ว่าง, Service มีแต่ไม่มี backend

**สาเหตุที่พบบ่อย:** readinessProbe path/port ผิด, label selector ไม่ตรง

**ขั้นตอน:**

```bash
kubectl -n aetherbank describe pod -l app=ledger-api
kubectl -n aetherbank get pods -o wide
kubectl -n aetherbank get svc ledger-api -o yaml | grep -A5 selector
```

แก้ probe หรือ label แล้วรอ Pod Ready

---

## อาการ: CrashLoopBackOff

**สัญญาณ:** `Restart Count` สูง, logs มี auth error ไป DB

**ขั้นตอน:**

```bash
kubectl -n aetherbank logs deploy/ledger-api --previous
kubectl -n aetherbank get secret db-secret -o yaml # ตรวจว่ามี key ครบ (อย่าพิมพ์ค่า secret ลงแชท)
```

แก้ Secret / env แล้ว `kubectl -n aetherbank rollout restart deploy/ledger-api`

---

## อาการ: PVC Pending

**สัญญาณ:** Pod Pending, Events บอกว่า volume ยัง provision ไม่ได้

**ขั้นตอน:**

```bash
kubectl -n aetherbank describe pvc pgdata
kubectl get storageclass
```

ตรวจว่ามี default StorageClass หรือระบุ `storageClassName` ให้ถูก

---

## อาการ: Ingress ไม่ตอบ

```bash
kubectl -n ingress-nginx get pods
kubectl -n aetherbank describe ingress aether
curl -vk https://aether.local/api
```

ตรวจ TLS secret ชื่อตรงกับ Ingress, `/etc/hosts` ชี้ IP ถูกต้อง, addon ingress พร้อม
