#!/bin/bash
# Deploys the retail store application using external RDS databases for the Catalog and Orders Services
# Prerequisites: Run setup-eso.sh first

set -e

NAMESPACE="retail-app"
CHART_VERSION="1.4.0"
REGISTRY="oci://public.ecr.aws/aws-containers"
SCRIPT_DIR="$(dirname "$0")"
VALUES_DIR="$SCRIPT_DIR/../kubernetes"

# Get RDS endpoints from Terraform
echo "=== Getting RDS endpoints from Terraform ==="
CATALOG_ENDPOINT=$(terraform -chdir="$SCRIPT_DIR/../terraform" output -raw catalog_mysql_endpoint | cut -d':' -f1)
ORDERS_ENDPOINT=$(terraform -chdir="$SCRIPT_DIR/../terraform" output -raw orders_postgres_endpoint | cut -d':' -f1)

echo "Catalog MySQL: $CATALOG_ENDPOINT"
echo "Orders PostgreSQL: $ORDERS_ENDPOINT"

# Verify secrets exist (created by ESO)
echo "=== Verifying secrets exist ==="
if ! kubectl get secret catalog-db-credentials -n $NAMESPACE > /dev/null 2>&1; then
  echo "ERROR: catalog-db-credentials not found. Run setup-eso.sh first."
  exit 1
fi

if ! kubectl get secret orders-db-credentials -n $NAMESPACE > /dev/null 2>&1; then
  echo "ERROR: orders-db-credentials not found. Run setup-eso.sh first."
  exit 1
fi
echo "Secrets verified!"

# Deploy services
echo "=== Deploying Catalog (MySQL RDS) ==="
helm install catalog $REGISTRY/retail-store-sample-catalog-chart:$CHART_VERSION \
  --namespace $NAMESPACE \
  -f $VALUES_DIR/catalog-values.yaml \
  --set app.persistence.endpoint="$CATALOG_ENDPOINT:3306" \
  --wait

echo "=== Deploying Cart (DynamoDB Local) ==="
helm install cart $REGISTRY/retail-store-sample-cart-chart:$CHART_VERSION \
  --namespace $NAMESPACE \
  --set dynamodb.create=true \
  --set app.persistence.provider=dynamodb \
  --wait

echo "=== Deploying Orders (PostgreSQL RDS) ==="
helm install orders $REGISTRY/retail-store-sample-orders-chart:$CHART_VERSION \
  --namespace $NAMESPACE \
  -f $VALUES_DIR/orders-values.yaml \
  --set app.persistence.endpoint="$ORDERS_ENDPOINT:5432"

# Fix Helm chart bugs for external RDS
echo "=== Patching Orders for external RDS ==="

# Get password from secret (already synced by ESO)
ORDERS_PASSWORD=$(kubectl get secret orders-db-credentials -n $NAMESPACE -o jsonpath='{.data.RETAIL_ORDERS_PERSISTENCE_PASSWORD}' | base64 -d)

# Patch configmap with required env vars
kubectl patch configmap orders -n $NAMESPACE --type merge -p "{
  \"data\":{
    \"RETAIL_ORDERS_PERSISTENCE_ENDPOINT\":\"$ORDERS_ENDPOINT:5432\",
    \"RETAIL_ORDERS_PERSISTENCE_DB_NAME\":\"orders_db\",
    \"SPRING_PROFILES_ACTIVE\":\"postgresql\",
    \"SPRING_DATASOURCE_URL\":\"jdbc:postgresql://$ORDERS_ENDPOINT:5432/orders_db\",
    \"SPRING_DATASOURCE_USERNAME\":\"orders\",
    \"SPRING_DATASOURCE_PASSWORD\":\"$ORDERS_PASSWORD\"
  }
}"

# Patch RabbitMQ secret with default credentials
kubectl patch secret orders-rabbitmq -n $NAMESPACE --type merge -p '{"data":{"RETAIL_ORDERS_MESSAGING_RABBITMQ_USERNAME":"Z3Vlc3Q=","RETAIL_ORDERS_MESSAGING_RABBITMQ_PASSWORD":"Z3Vlc3Q="}}'

# Add db credentials secret to deployment
kubectl patch deployment orders -n $NAMESPACE --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/envFrom/-", "value": {"secretRef": {"name": "orders-db-credentials"}}}]'

kubectl rollout status deployment/orders -n $NAMESPACE --timeout=120s

echo "=== Deploying Checkout (Redis) ==="
helm install checkout $REGISTRY/retail-store-sample-checkout-chart:$CHART_VERSION \
  --namespace $NAMESPACE \
  --set redis.create=true \
  --set app.persistence.provider=redis \
  --set app.endpoints.orders=http://orders:80 \
  --wait

echo "=== Deploying UI ==="
helm install ui $REGISTRY/retail-store-sample-ui-chart:$CHART_VERSION \
  --namespace $NAMESPACE \
  --set app.endpoints.catalog=http://catalog:80 \
  --set app.endpoints.carts=http://cart-carts:80 \
  --set app.endpoints.orders=http://orders:80 \
  --set app.endpoints.checkout=http://checkout:80 \
  --wait

# Show status
echo ""
echo "=== Deployment Complete ==="
echo ""
kubectl get pods -n $NAMESPACE

echo ""
echo "=== Starting Port Forwards ==="
kubectl port-forward svc/ui -n $NAMESPACE 8080:80 &
kubectl port-forward svc/orders -n $NAMESPACE 8082:80 &

echo ""
echo "Access the app:"
echo "  UI:     http://localhost:8080"
echo "  Orders: http://localhost:8082/orders"
echo ""
echo "To stop port-forwards: pkill -f 'port-forward'"