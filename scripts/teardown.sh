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

destroy_component "SQS Infra" "sqs-infra"
destroy_component "RDS"        "rds-infra"
destroy_component "EKS"        "eks-infra"
destroy_component "Networking" "networking-infra"

echo ""
echo "--- Stopping Concourse ---"
"${SCRIPT_DIR}/stop-concourse.sh"

echo ""
echo "All done. AWS infrastructure destroyed and Concourse stopped."
echo "Run scripts/delete-terraform-backend.sh to remove the S3 state bucket too."

