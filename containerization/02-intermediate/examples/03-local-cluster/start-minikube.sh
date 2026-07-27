#!/usr/bin/env bash
set -euo pipefail

minikube start --driver=docker --cpus=2 --memory=4096
minikube addons enable metrics-server
kubectl get nodes
echo "OK — context: $(kubectl config current-context)"
