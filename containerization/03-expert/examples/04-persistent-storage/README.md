# 04 — Persistent Storage (PVC)

```bash
kubectl apply -f pvc.yaml
kubectl apply -f pod.yaml

kubectl exec -it volume-demo -- sh -c "echo hello > /data/hello.txt && cat /data/hello.txt"
kubectl delete pod volume-demo
kubectl apply -f pod.yaml
kubectl exec -it volume-demo -- cat /data/hello.txt
# ควรยังเห็น hello ถ้า PVC bind กับ volume เดิม
```
