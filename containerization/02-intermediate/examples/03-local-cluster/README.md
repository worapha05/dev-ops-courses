# 03 — Local Cluster Setup

เลือกอย่างใดอย่างหนึ่ง

## Minikube

```bash
chmod +x start-minikube.sh
./start-minikube.sh
```

## Kind

```bash
chmod +x start-kind.sh
./start-kind.sh
```

ตรวจ:

```bash
kubectl get nodes
kubectl get pods -A
```

> **คำใบ้:** หลัง deploy Service แล้ว ถ้า `minikube service --url` ค้าง (พบบ่อยกับ `--driver=docker`) ให้ใช้:
>
> ```bash
> kubectl port-forward svc/<ชื่อ-service> 8080:80
> ```
