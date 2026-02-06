#!/bin/bash
# Uninstalls the retail store application from EKS

NAMESPACE="retail-app"

echo "=== Uninstalling Helm releases ==="
helm uninstall ui --namespace $NAMESPACE --ignore-not-found
helm uninstall checkout --namespace $NAMESPACE --ignore-not-found
helm uninstall orders --namespace $NAMESPACE --ignore-not-found
helm uninstall cart --namespace $NAMESPACE --ignore-not-found
helm uninstall catalog --namespace $NAMESPACE --ignore-not-found

echo "=== Deleting namespace ==="
kubectl delete namespace $NAMESPACE --ignore-not-found

echo "=== Uninstall complete ==="