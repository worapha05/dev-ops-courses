# 01 — ConfigMaps & Secrets

```bash
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f deployment.yaml

kubectl exec deploy/config-demo -- printenv | grep -E 'LOG_LEVEL|DB_'
kubectl exec deploy/config-demo -- cat /etc/config/APP_MODE
```

> `secret.yaml` ในตัวอย่างใช้รหัสผ่าน demo เท่านั้น — อย่าใช้ใน production
