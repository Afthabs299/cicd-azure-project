#!/usr/bin/env bash
# ============================================================
# provision.sh — Provision Azure infrastructure via Terraform
# Usage: ./scripts/provision.sh [plan|apply|destroy]
# ============================================================
set -euo pipefail

ACTION="${1:-plan}"

echo "▶ Initialising Terraform..."
cd terraform
terraform init

case "$ACTION" in
  plan)
    echo "▶ Running terraform plan..."
    terraform plan -out=tfplan
    ;;
  apply)
    echo "▶ Running terraform apply..."
    terraform apply -auto-approve
    echo "✅ Infrastructure provisioned!"
    echo "ACR Login Server: $(terraform output -raw acr_login_server)"
    echo "AKS Cluster:      $(terraform output -raw aks_cluster_name)"
    ;;
  destroy)
    echo "⚠️  Destroying all infrastructure..."
    terraform destroy -auto-approve
    echo "✅ Infrastructure destroyed."
    ;;
  *)
    echo "Usage: $0 [plan|apply|destroy]"
    exit 1
    ;;
esac
