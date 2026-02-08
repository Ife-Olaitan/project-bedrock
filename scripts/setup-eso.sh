#!/bin/bash
# Sets up External Secrets Operator (ESO) and configures it to sync from AWS Secrets Manager

set -e

SCRIPT_DIR="$(dirname "$0")"

# Get the IAM role ARN for ESO from Terraform
echo "=== Getting ESO role ARN from Terraform ==="
ESO_ROLE_ARN=$(terraform -chdir="$SCRIPT_DIR/../terraform" output -raw eso_role_arn)
echo "ESO Role ARN: $ESO_ROLE_ARN"

# Install ESO using Helm
echo "=== Adding External Secrets Helm repo ==="
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

echo "=== Installing External Secrets Operator ==="
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ESO_ROLE_ARN" \
  --wait

echo "=== Waiting for ESO to be ready ==="
kubectl wait --for=condition=available --timeout=120s \
  deployment/external-secrets -n external-secrets

# Create namespace first (needed for ExternalSecrets)
echo "=== Creating retail-app namespace ==="
kubectl create namespace retail-app --dry-run=client -o yaml | kubectl apply -f -

echo "=== Creating ClusterSecretStore ==="
kubectl apply -f "$SCRIPT_DIR/../kubernetes/secretstore.yaml"

echo "=== Creating ExternalSecrets ==="
kubectl apply -f "$SCRIPT_DIR/../kubernetes/external-secrets.yaml"

# Verify
echo "=== Waiting for secrets to sync ==="
sleep 10

echo ""
echo "=== ESO Setup Complete ==="
echo ""
echo "ExternalSecrets status:"
kubectl get externalsecrets -n retail-app
echo ""
echo "Kubernetes Secrets created:"
kubectl get secrets -n retail-app