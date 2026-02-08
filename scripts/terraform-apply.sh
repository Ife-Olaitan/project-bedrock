#!/bin/bash
# Creates all Terraform infrastructure resources

set -e  # Exit on any error

STATE_BUCKET="project-bedrock-state-buc"
AWS_REGION="us-east-1"

# Check if S3 backend bucket exists, create if it doesn't
echo "=== Checking S3 backend bucket ==="
if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
  echo "Bucket '$STATE_BUCKET' already exists"
else
  echo "Bucket '$STATE_BUCKET' not found. Creating..."
  aws s3api create-bucket --bucket "$STATE_BUCKET" --region "$AWS_REGION"

  echo "Enabling versioning on bucket..."
  aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" --versioning-configuration Status=Enabled

  echo "Bucket created successfully"
fi

# Navigate to terraform folder (assumes script is run from project root)
cd terraform

echo "=== Initializing Terraform ==="
terraform init

echo "=== Validating Terraform configuration ==="
terraform validate

echo "=== Planning infrastructure ==="
terraform plan

echo ""
read -p "Do you want to apply these changes? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo "=== Applying infrastructure ==="
terraform apply -auto-approve

echo "=== Terraform apply complete ==="
echo ""
echo "Next steps:"
echo "  1. Configure kubectl:"
echo "     aws eks update-kubeconfig --name project-bedrock-cluster --region us-east-1 --alias admin"
echo ""
echo "  2. Deploy the app:"
echo "     ./scripts/deploy-retail-app-rds.sh"