#!/usr/bin/env bash
# ============================================================
# deploy.sh — Manual deployment script (run locally or in CI)
# Usage: ./scripts/deploy.sh <image-tag>
# ============================================================
set -euo pipefail

IMAGE_TAG="${1:-latest}"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:-cicddemoacr.azurecr.io}"
IMAGE_NAME="flask-app"
K8S_NAMESPACE="default"

echo "▶ Logging in to ACR..."
az acr login --name "$ACR_LOGIN_SERVER"

echo "▶ Building Docker image..."
docker build -t "$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG" ./app

echo "▶ Pushing image to ACR..."
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"

echo "▶ Updating kubeconfig for AKS..."
az aks get-credentials \
  --resource-group cicd-demo-rg \
  --name cicd-demo-aks \
  --overwrite-existing

echo "▶ Substituting image tag in manifests..."
sed "s|\$(ACR_LOGIN_SERVER)|$ACR_LOGIN_SERVER|g; s|\$(IMAGE_TAG)|$IMAGE_TAG|g" \
  k8s/deployment.yaml | kubectl apply -f - -n "$K8S_NAMESPACE"

kubectl apply -f k8s/service.yaml -n "$K8S_NAMESPACE"

echo "▶ Waiting for rollout..."
kubectl rollout status deployment/flask-app -n "$K8S_NAMESPACE"

echo "✅ Deployment complete! Image: $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
