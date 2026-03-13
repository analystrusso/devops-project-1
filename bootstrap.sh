#!/bin/bash
# bootstrap.sh - Run this when setting up fresh infrastructure
kubectl create configmap apache-cm0 \
  --from-file=website/ \
  --namespace=default \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f apache-deployment.yaml
kubectl apply -f apache-metrics.yaml
