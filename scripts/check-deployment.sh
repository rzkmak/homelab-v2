#!/bin/bash
set -e

echo "=== Checking ArgoCD Applications ==="
kubectl get applications -n argocd

echo ""
echo "=== Checking Infrastructure Applications ==="
kubectl get application infrastructure -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null && echo "" || echo "Infrastructure application not found"

echo ""
echo "=== Checking Sealed Secrets Application ==="
kubectl get application sealed-secrets -n argocd 2>/dev/null || echo "Sealed-secrets application not found yet"

echo ""
echo "=== Checking Sealed Secrets Deployment ==="
kubectl get deployment -n kube-system 2>/dev/null | grep sealed || echo "No sealed-secrets deployment found yet"

echo ""
echo "=== All Pods Status ==="
kubectl get pods -A | grep -E "NAMESPACE|sealed|argocd"
