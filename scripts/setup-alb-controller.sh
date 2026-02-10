#!/bin/bash
# Installs AWS Load Balancer Controller and creates Ingress for the UI

set -e

SCRIPT_DIR="$(dirname "$0")"

# Get values from Terraform
echo "=== Getting values from Terraform ==="
ALB_ROLE_ARN=$(terraform -chdir="$SCRIPT_DIR/../terraform" output -raw alb_controller_role_arn)
CLUSTER_NAME=$(terraform -chdir="$SCRIPT_DIR/../terraform" output -raw cluster_name)
VPC_ID=$(terraform -chdir="$SCRIPT_DIR/../terraform" output -raw vpc_id)
REGION=$(terraform -chdir="$SCRIPT_DIR/../terraform" output -raw region)
ACM_CERTIFICATE_ARN=$(terraform -chdir="$SCRIPT_DIR/../terraform" output -raw acm_certificate_arn)

echo "ALB Controller Role ARN: $ALB_ROLE_ARN"
echo "Cluster Name: $CLUSTER_NAME"
echo "VPC ID: $VPC_ID"
echo "Region: $REGION"
echo "ACM Certificate ARN: $ACM_CERTIFICATE_ARN"

# Install AWS Load Balancer Controller using Helm
echo ""
echo "=== Adding EKS Helm repo ==="
helm repo add eks https://aws.github.io/eks-charts
helm repo update

echo ""
echo "=== Installing AWS Load Balancer Controller ==="
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ALB_ROLE_ARN" \
  --set region="$REGION" \
  --set vpcId="$VPC_ID" \
  --wait

echo ""
echo "=== Waiting for controller to be ready ==="
kubectl wait --for=condition=available --timeout=120s \
  deployment/aws-load-balancer-controller -n kube-system

echo ""
echo "=== Creating Ingress for UI ==="
# Substitute the ACM certificate ARN into the ingress manifest
sed "s|\${ACM_CERTIFICATE_ARN}|$ACM_CERTIFICATE_ARN|g" "$SCRIPT_DIR/../kubernetes/ingress.yaml" | kubectl apply -f -

# Wait for ALB to be provisioned
echo ""
echo "=== Waiting for ALB to be provisioned (this may take a few minutes) ==="
sleep 30

# Get the ALB URL
ALB_URL=""
for i in {1..20}; do
  ALB_URL=$(kubectl get ingress ui-ingress -n retail-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  if [ -n "$ALB_URL" ]; then
    break
  fi
  echo "Waiting for ALB hostname... (attempt $i/20)"
  sleep 15
done

echo ""
echo "=== ALB Controller Setup Complete ==="
echo ""
if [ -n "$ALB_URL" ]; then
  echo "ALB Hostname: $ALB_URL"
  echo ""
  echo "=== NEXT STEP: Add CNAME record in Porkbun ==="
  echo "Type:   CNAME"
  echo "Host:   @ (or leave blank for root domain)"
  echo "Answer: $ALB_URL"
  echo ""
  echo "After DNS propagates (~5 min), access the app at:"
  echo "  https://myprojectbedrock.xyz"
else
  echo "ALB is still provisioning. Check status with:"
  echo "  kubectl get ingress ui-ingress -n retail-app"
fi