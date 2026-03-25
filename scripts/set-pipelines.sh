#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINES_DIR="${SCRIPT_DIR}/../concourse/pipelines"

# Derive the repo URI from the actual git remote so the Concourse worker clones
# from GitHub (or wherever origin points), not from a local volume mount.
GIT_REPO_URI="$(git -C "${SCRIPT_DIR}" remote get-url origin)"
GIT_BRANCH="main"
AWS_REGION="us-east-1"
PROJECT_NAME="matt-lyle-terraform-demo"
EKS_CLUSTER_NAME="${PROJECT_NAME}-eks"
TF_DIR="${SCRIPT_DIR}/../terraform"

# Attempt to read values from Terraform outputs after infra is applied.
# Falls back to empty strings if not yet applied — re-run set-pipelines.sh after apply.
get_tf_output() {
  terraform -chdir="${TF_DIR}/$1" output -raw "$2" 2>/dev/null || echo ""
}

echo "Reading Terraform outputs (silently skips modules not yet applied)..."
ECR_REGISTRY=$(get_tf_output      "eks-infra" "ecr_registry")
AWS_ACCOUNT_ID=$(echo "${ECR_REGISTRY}" | cut -d. -f1)
SQS_QUEUE_URL=$(get_tf_output     "sqs-infra" "sqs_queue_url")
DB_HOST=$(get_tf_output           "rds-infra" "db_endpoint")
DB_NAME=$(get_tf_output           "rds-infra" "db_name")
DB_USER=$(get_tf_output           "rds-infra" "db_username")
SSM_DB_PASSWORD_PATH=$(get_tf_output "rds-infra" "db_password_ssm_path")

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
  deploy-infra
  install-ingress
  install-monitoring
  deploy-services
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
    --var "project_name=${PROJECT_NAME}" \
    --var "git_repo_uri=${GIT_REPO_URI}" \
    --var "git_branch=${GIT_BRANCH}" \
    --var "eks_cluster_name=${EKS_CLUSTER_NAME}" \
    --var "ecr_registry=${ECR_REGISTRY}" \
    --var "aws_account_id=${AWS_ACCOUNT_ID}" \
    --var "sqs_queue_url=${SQS_QUEUE_URL}" \
    --var "db_host=${DB_HOST}" \
    --var "db_name=${DB_NAME}" \
    --var "db_user=${DB_USER}" \
    --var "ssm_db_password_path=${SSM_DB_PASSWORD_PATH}"
  fly -t local unpause-pipeline --pipeline "${pipeline}"
done

echo ""
echo "All pipelines set. Open http://localhost:8080"
