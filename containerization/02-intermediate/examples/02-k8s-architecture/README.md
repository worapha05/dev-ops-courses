# 02 — Kubernetes Architecture Glossary

## Control Plane

| Component               | หน้าที่สั้น ๆ         |
| ----------------------- | --------------------- |
| kube-apiserver          | ประตู API ของ cluster |
| etcd                    | เก็บ state            |
| kube-scheduler          | เลือก Node ให้ Pod    |
| kube-controller-manager | reconcile controllers |

## Worker Node

| Component         | หน้าที่สั้น ๆ                 |
| ----------------- | ----------------------------- |
| kubelet           | รัน Pod ตาม spec จาก API      |
| container runtime | containerd / CRI-O ฯลฯ        |
| kube-proxy        | เส้นทาง Service (ขึ้นกับโหมด) |

## Object hierarchy (ย่อ)

```
Deployment
 └── ReplicaSet
 └── Pod(s)
  └── Container(s)
```

Service เลือก Pod ผ่าน **labels** ไม่ผ่านชื่อ Pod โดยตรง
