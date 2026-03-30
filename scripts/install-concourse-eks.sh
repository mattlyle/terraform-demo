#!/usr/bin/env bash
# Installs Concourse CI into the EKS cluster via Helm.
# Run this once after the EKS cluster is up (after terraform apply on eks-infra).
# Uses the bundled PostgreSQL subchart — pipeline state is ephemeral, but
# set-pipelines.sh re-registers everything so that's fine.
#
# After this script completes, the Concourse URL is printed.
# DNS propagation takes 1-2 minutes, then log in manually:
#   fly -t eks login -c <url> -u admin -p admin
#   bash scripts/set-pipelines.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CLUSTER_NAME="matt-lyle-terraform-demo-eks"
AWS_REGION="us-east-1"
CONCOURSE_NAMESPACE="concourse"
CONCOURSE_VERSION="20.1.3"   # Helm chart version (Concourse 8.1.1)
ADMIN_USER="admin"
# Set CONCOURSE_ADMIN_PASS in your environment to override the default.
ADMIN_PASS="${CONCOURSE_ADMIN_PASS:-admin}"

echo "Updating kubeconfig for cluster: ${CLUSTER_NAME}"
aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}"
echo

echo "Adding Concourse Helm repo..."
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm repo update
echo

echo "Installing Concourse into namespace: ${CONCOURSE_NAMESPACE}"
helm upgrade --install concourse concourse/concourse \
  --namespace "${CONCOURSE_NAMESPACE}" \
  --create-namespace \
  --version "${CONCOURSE_VERSION}" \
  --set web.service.api.type=LoadBalancer \
  --set secrets.localUsers="${ADMIN_USER}:${ADMIN_PASS}" \
  --set concourse.web.auth.mainTeam.localUser="${ADMIN_USER}" \
  --set postgresql.enabled=true \
  --set postgresql.persistence.storageClass=gp2-csi \
  --set worker.persistence.storageClass=gp2-csi \
  --wait --timeout 10m
echo

CONCOURSE_URL=$(kubectl get svc concourse-web \
  --namespace "${CONCOURSE_NAMESPACE}" \
  --output jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)

if [ -z "${CONCOURSE_URL:-}" ]; then
  echo "LoadBalancer hostname not yet assigned. Get it later with:"
  echo "  kubectl get svc concourse-web -n ${CONCOURSE_NAMESPACE}"
  exit 0
fi

# Set externalUrl now that we know the LB hostname — required so the OAuth
# login redirect points to the real URL instead of 127.0.0.1.
echo "Setting externalUrl to http://${CONCOURSE_URL}:8080..."
helm upgrade concourse concourse/concourse \
  --namespace "${CONCOURSE_NAMESPACE}" \
  --version "${CONCOURSE_VERSION}" \
  --reuse-values \
  --set concourse.web.externalUrl="http://${CONCOURSE_URL}:8080"

echo ""
echo "Concourse is up at: http://${CONCOURSE_URL}:8080"
echo ""
echo "DNS propagation can take 1-2 minutes. Once reachable, log in and set pipelines:"
echo "  fly -t eks login -c http://${CONCOURSE_URL}:8080 -u ${ADMIN_USER} -p ${ADMIN_PASS}"
echo "  bash scripts/set-pipelines.sh"
