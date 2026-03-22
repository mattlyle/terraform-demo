#!/usr/bin/env bash

# Creates the S3 bucket and DynamoDB table for Terraform backend

set -euo pipefail

PROJECT_NAME="matt-lyle-terraform-demo"
AWS_REGION="us-east-1"
BUCKET_NAME="${PROJECT_NAME}-tfstate"
TABLE_NAME="${PROJECT_NAME}-tfstate-lock"

echo "Creating S3 bucket: ${BUCKET_NAME}"
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "  already exists, skipping"
else
  aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}"
  aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
  aws s3api put-public-access-block --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
    'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
fi

echo "Creating DynamoDB table: ${TABLE_NAME}"
if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "  already exists, skipping"
else
  aws dynamodb create-table \
    --table-name "${TABLE_NAME}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${AWS_REGION}"
  aws dynamodb wait table-exists --table-name "${TABLE_NAME}" --region "${AWS_REGION}"
fi

echo ""
echo "Done! Update the backend block in terraform/networking.tf:"
echo ""
echo "  bucket         = \"${BUCKET_NAME}\""
echo "  key            = \"${PROJECT_NAME}/terraform.tfstate\""
echo "  region         = \"${AWS_REGION}\""
echo "  dynamodb_table = \"${TABLE_NAME}\""
echo ""
echo "Then run: terraform init -reconfigure"
