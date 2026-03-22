#!/usr/bin/env bash
# Registers all Concourse pipelines.
# Requires fly to be logged in first:
#   fly -t local login -c http://localhost:8080 -u admin -p admin
#
# AWS credentials are read from your shell environment.
# Export them before running, e.g.:
#   export AWS_ACCESS_KEY_ID=...
#   export AWS_SECRET_ACCESS_KEY=...
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINES_DIR="${SCRIPT_DIR}/../concourse/pipelines"

# Project is volume-mounted into Concourse at /workspace -- no GitHub push needed.
# Just commit locally before triggering a pipeline run.
GIT_REPO_URI="/workspace"
GIT_BRANCH="main"
AWS_REGION="us-east-1"
EKS_CLUSTER_NAME="matt-lyle-terraform-demo-eks"

if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ]; then
  CREDS_FILE="${HOME}/.aws/credentials"
  if [ -f "${CREDS_FILE}" ]; then
    AWS_ACCESS_KEY_ID=$(awk -F= '/aws_access_key_id/{print $2}' "${CREDS_FILE}" | head -1 | tr -d ' ')
    AWS_SECRET_ACCESS_KEY=$(awk -F= '/aws_secret_access_key/{print $2}' "${CREDS_FILE}" | head -1 | tr -d ' ')
  fi
fi

if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ]; then
  echo "Could not find AWS credentials. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY or run: aws configure"
  exit 1
fi

# Log in to the local Concourse target if not already authenticated.
if ! fly -t local status &>/dev/null; then
  echo "Logging in to Concourse..."
  fly -t local login -c http://localhost:8080 -u admin -p admin
fi

PIPELINES=(
  networking-infra
  eks-infra
  rds-infra
  install-monitoring
  deploy-frontend
  deploy-api-server
  deploy-backend-worker
  deploy-user-simulator
)

for pipeline in "${PIPELINES[@]}"; do
  echo "Setting pipeline: ${pipeline}"
  fly -t local set-pipeline \
    --non-interactive \
    --pipeline "${pipeline}" \
    --config "${PIPELINES_DIR}/${pipeline}.yml" \
    --var "aws_access_key_id=${AWS_ACCESS_KEY_ID}" \
    --var "aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" \
    --var "aws_region=${AWS_REGION}" \
    --var "git_repo_uri=${GIT_REPO_URI}" \
    --var "git_branch=${GIT_BRANCH}" \
    --var "eks_cluster_name=${EKS_CLUSTER_NAME}"
  fly -t local unpause-pipeline --pipeline "${pipeline}"
done

echo ""
echo "All pipelines set. Open http://localhost:8080"
