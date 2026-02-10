#!/bin/bash
# Destroys all Terraform infrastructure resources

set -e  # Exit on any error

cd terraform

read -p "Are you sure you want to destroy everything? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo "=== Destroying infrastructure ==="
terraform destroy -auto-approve

echo "=== Force Delete Secret Managers ==="
aws secretsmanager delete-secret --secret-id project-bedrock-catalog-db-credentials --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id project-bedrock-orders-db-credentials --force-delete-without-recovery --region us-east-1

echo "=== Terraform destroy complete ==="