# 03 — Ingress & TLS

## เตรียม Ingress Controller (Minikube)

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```

## TLS Secret demo (self-signed)

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=shop.example.local/O=bootcamp"
kubectl create secret tls shop-tls --cert=tls.crt --key=tls.key
rm -f tls.key tls.crt
```

หรือใช้ไฟล์ [`tls-secret.yaml`](./tls-secret.yaml) ที่เป็นตัวอย่างโครงสร้าง (ต้องใส่ข้อมูลจริงก่อน apply)

```bash
kubectl apply -f frontend-backend.yaml
kubectl apply -f ingress.yaml

# เพิ่ม host ใน /etc/hosts ให้ชี้ IP ของ minikube / ingress
minikube ip
# แล้วทดสอบ
curl -k https://shop.example.local/api
```
