# เฉลย Lab Expert — AetherBank

```text
lab/solution/
├── README.md
├── NOTES.md
├── RUNBOOK.md
└── k8s/
 ├── 00-namespace.yaml
 ├── 01-configmap.yaml
 ├── 02-secret.yaml
 ├── 03-db-pvc.yaml
 ├── 04-db.yaml
 ├── 05-ledger-api.yaml
 ├── 06-frontend.yaml
 ├── 07-hpa.yaml
 ├── 08-ingress.yaml
 └── 09-networkpolicy.yaml
```

## วิธีใช้

```bash
# 1) cluster + addons
minikube start
minikube addons enable metrics-server
minikube addons enable ingress

# 2) TLS secret (self-signed)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt \
  -subj "/CN=aether.local/O=aetherbank"
kubectl create namespace aetherbank --dry-run=client -o yaml | kubectl apply -f -
kubectl -n aetherbank create secret tls aether-tls \
  --cert=/tmp/tls.crt --key=/tmp/tls.key \
  --dry-run=client -o yaml | kubectl apply -f -

# 3) Apply manifests
kubectl apply -f k8s/

# 4) รอพร้อม
kubectl -n aetherbank get pods,svc,ingress,hpa,pvc

# 5) ชี้ DNS ท้องถิ่น
echo "$(minikube ip) aether.local" | sudo tee -a /etc/hosts
curl -k https://aether.local/api
# เฉลยใช้ http-echo เป็นตัวแทน API — ตอบข้อความที่ path ใดก็ได้

# ทางเลือกรวดเร็วถ้า Ingress /etc/hosts ยุ่งยาก (Docker driver):
# kubectl -n aetherbank port-forward svc/ledger-api 8080:80
# curl http://127.0.0.1:8080/
```

> Image `ledger-api` ในเฉลยใช้ `hashicorp/http-echo` เป็นตัวแทนเพื่อให้ apply ได้ทันทีโดยไม่ต้อง build
> ในงานจริงให้แทนด้วย multi-stage image ของคุณจากระดับ Intermediate
>
> **คำใบ้:** บน Minikube `--driver=docker` การเข้าผ่าน Ingress/`minikube ip` อาจต้องตั้ง `/etc/hosts` หรือ tunnel — ถ้าติด ให้ใช้ `kubectl port-forward` ทดสอบ Service ก่อน
