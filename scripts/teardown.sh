#!/usr/bin/env bash

# Tears down everything created during the demo in reverse dependency order
# scripts/delete-terraform-backend.sh separately if you want a full cleanup.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/../terraform"

echo ""
echo "WARNING: This will destroy all demo AWS infrastructure and stop Concourse."
echo "Terraform state will remain in S3 (run delete-terraform-backend.sh to remove it too)."
echo ""
read -r -p "Type 'yes' to continue: " answer
if [ "${answer}" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

destroy_component() {
  local name="$1"
  local dir="${TF_DIR}/$2"

  echo ""
  echo "--- Destroying: ${name} ---"

  if [ ! -d "${dir}/.terraform" ]; then
    echo "Initializing..."
    terraform -chdir="${dir}" init -input=false -reconfigure
  fi

  terraform -chdir="${dir}" destroy -auto-approve -input=false
  echo "Done: ${name}"
}

destroy_component "SQS Infra" "4-sqs-infra"
destroy_component "RDS"        "3-rds-infra"

# ── Remove Kubernetes-managed AWS resources before destroying EKS ────────────
# The NGINX Ingress Controller and kube-prometheus-stack each create AWS
# resources (Load Balancer, etc.) that live outside Terraform state.
# They must be removed first — otherwise the VPC destroy will fail because
# AWS refuses to delete subnets that still have active ELBs attached.
echo ""
echo "--- Removing Helm releases and Kubernetes-managed AWS resources ---"
TF_DIR_EKS="${TF_DIR}/1-eks-infra"
if [ ! -d "${TF_DIR_EKS}/.terraform" ]; then
  terraform -chdir="${TF_DIR_EKS}" init -input=false -reconfigure
fi
CLUSTER_NAME=$(terraform -chdir="${TF_DIR_EKS}" output -raw cluster_name 2>/dev/null || echo "")
AWS_REGION="us-east-1"
if [ -n "${CLUSTER_NAME}" ]; then
  aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}" 2>/dev/null || true
  # Uninstalling ingress-nginx deletes the LoadBalancer service, which
  # triggers AWS to deprovision the ELB before we destroy the VPC.
  helm uninstall concourse --namespace concourse 2>/dev/null || true
  helm uninstall ingress-nginx --namespace ingress-nginx 2>/dev/null || true
  helm uninstall kube-prometheus-stack --namespace monitoring 2>/dev/null || true
  echo "Helm releases removed."
else
  echo "Could not determine cluster name — skipping Helm cleanup (cluster may already be gone)."
fi

destroy_component "Post-EKS Config" "2-post-eks-config"
destroy_component "EKS"        "1-eks-infra"
destroy_component "Networking" "0-networking-infra"

echo ""
echo "All done. AWS infrastructure destroyed."
echo "Run scripts/delete-terraform-backend.sh to remove the S3 state bucket too."

