#!/bin/bash
# Deploys the retail store application to EKS using Helm

set -e  # Exit on any error

NAMESPACE="retail-app"
CHART_VERSION="1.4.0"
REGISTRY="oci://public.ecr.aws/aws-containers"

echo "=== Creating namespace ==="
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "=== Deploying Catalog (MySQL) ==="
helm install catalog $REGISTRY/retail-store-sample-catalog-chart:$CHART_VERSION \
  --namespace $NAMESPACE \
  --set mysql.create=true \
  --set app.persistence.provider=mysql \
  --wait

echo "=== Deploying Cart (DynamoDB Local) ==="
helm install cart $REGISTRY/retail-store-sample-cart-chart:$CHART_VERSION \
  --namespace $NAMESPACE \
  --set dynamodb.create=true \
  --set app.persistence.provider=dynamodb \
  --wait

echo "=== Deploying Orders (PostgreSQL + RabbitMQ) ==="
helm install orders $REGISTRY/retail-store-sample-orders-chart:$CHART_VERSION \
  --namespace $NAMESPACE \
  --set postgresql.create=true \
  --set app.persistence.provider=postgresql \
  --set rabbitmq.create=true \
  --set app.messaging.provider=rabbitmq \
  --wait

echo "=== Deploying Checkout (Redis) ==="
helm install checkout $REGISTRY/retail-store-sample-checkout-chart:$CHART_VERSION \
  --namespace $NAMESPACE \
  --set redis.create=true \
  --set app.persistence.provider=redis \
  --wait

echo "=== Deploying UI ==="
helm install ui $REGISTRY/retail-store-sample-ui-chart:$CHART_VERSION \
  --namespace $NAMESPACE \
  --set app.endpoints.catalog=http://catalog:80 \
  --set app.endpoints.carts=http://cart-carts:80 \
  --set app.endpoints.orders=http://orders:80 \
  --set app.endpoints.checkout=http://checkout:80 \
  --wait

echo "=== Deployment complete ==="
kubectl get pods -n $NAMESPACE

echo ""
echo "To access the app, run:"
echo "  kubectl port-forward svc/ui -n $NAMESPACE 8080:80"
echo "Then open: http://localhost:8080"