# 02 — Probes & HPA

ต้องการ metrics-server:

```bash
minikube addons enable metrics-server
# รอสักครู่แล้ว
kubectl apply -f deployment.yaml
kubectl apply -f hpa.yaml
kubectl get hpa
kubectl top pods
```

สร้างโหลดจำลอง (optional):

```bash
kubectl run load --rm -it --image=busybox:1.36 --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://probe-demo/; done"
```
