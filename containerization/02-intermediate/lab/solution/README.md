# เฉลย Lab Intermediate — ParcelGo API

```text
lab/solution/
├── README.md
├── NOTES.md
├── app/
│ ├── Dockerfile
│ ├── .dockerignore
│ ├── package.json
│ └── src/server.js
└── k8s/
    ├── deployment.yaml
    ├── service-clusterip.yaml
    └── service-nodeport.yaml
```

## ขั้นตอนรันเฉลย

```bash
cd 02-intermediate/lab/solution/app
docker build -t parcelgo-api:1.0.0 .

# Minikube
minikube image load parcelgo-api:1.0.0

# หรือ Kind
# kind load docker-image parcelgo-api:1.0.0 --name bootcamp

cd ../k8s
kubectl apply -f .
kubectl get pods,svc -l app=parcelgo-api

# ทดสอบจาก host — แนะนำ port-forward (เสถียรบน Docker driver)
kubectl port-forward svc/parcelgo-api 8080:80
# อีกเทอร์มินัล: curl http://127.0.0.1:8080/health

# ทางเลือก Minikube (อาจค้างบน --driver=docker):
# minikube service parcelgo-api-nodeport --url
```
