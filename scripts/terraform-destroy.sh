#!/bin/bash
# Destroys all Terraform infrastructure resources

set -e  # Exit on any error

# Navigate to terraform folder (assumes script is run from project root)
cd terraform

echo "=== WARNING ==="
echo "This will destroy ALL infrastructure resources including:"
echo "  - EKS Cluster"
echo "  - VPC and networking"
echo "  - IAM roles and policies"
echo "  - S3 buckets"
echo "  - Lambda functions"
echo ""
read -p "Are you sure you want to destroy everything? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo "=== Destroying infrastructure ==="
terraform destroy

echo "=== Terraform destroy complete ==="