# 04 — Services & Networking

Manifest สำหรับ Deployment + Service หลายชนิด

```bash
# สร้าง cluster ก่อน แล้ว:
kubectl apply -f deployment.yaml
kubectl apply -f service-clusterip.yaml

# ทดสอบภายใน cluster
kubectl run curl --rm -it --image=curlimages/curl --restart=Never -- \
  curl -s http://demo-api.default.svc.cluster.local/
# http-echo ตอบข้อความเดียวกันทุก path (ไม่มี /health จริง)

# NodePort (local)
kubectl apply -f service-nodeport.yaml
# Minikube:
# minikube service demo-api-nodeport --url
```

> **คำใบ้:** ถ้า Minikube ใช้ Docker driver แล้ว `minikube service --url` ค้าง ให้ใช้:
>
> ```bash
> kubectl port-forward svc/demo-api 8080:80
> curl http://127.0.0.1:8080/
> ```
