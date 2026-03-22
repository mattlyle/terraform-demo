#!/usr/bin/env bash

# Deletes the S3 bucket and DynamoDB table created by bootstrap-terraform-backend.sh.

set -euo pipefail

PROJECT_NAME="matt-lyle-terraform-demo"
AWS_REGION="us-east-1"
BUCKET_NAME="${PROJECT_NAME}-tfstate"
TABLE_NAME="${PROJECT_NAME}-tfstate-lock"

echo "This will permanently delete:"
echo "  S3 bucket      : ${BUCKET_NAME}"
echo "  DynamoDB table : ${TABLE_NAME}"
echo ""
read -r -p "Are you sure? (yes/no): " CONFIRM
if [ "${CONFIRM}" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo "Deleting S3 bucket: ${BUCKET_NAME}"
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  aws s3 rm "s3://${BUCKET_NAME}" --recursive
  aws s3api delete-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}"
  echo "  done"
else
  echo "  not found, skipping"
fi

echo "Deleting DynamoDB table: ${TABLE_NAME}"
if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  aws dynamodb delete-table --table-name "${TABLE_NAME}" --region "${AWS_REGION}"
  aws dynamodb wait table-not-exists --table-name "${TABLE_NAME}" --region "${AWS_REGION}"
  echo "  done"
else
  echo "  not found, skipping"
fi

echo ""
echo "Done!"
