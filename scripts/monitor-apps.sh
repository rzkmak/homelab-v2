#!/bin/bash
# Monitor ArgoCD applications without watch command

echo "Monitoring ArgoCD Applications"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    clear
    echo "=== ArgoCD Applications Status ==="
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    kubectl get applications -n argocd 2>/dev/null

    echo ""
    echo "=== Application Details ==="

    # Check if root app exists and show its details
    if kubectl get application root -n argocd >/dev/null 2>&1; then
        echo ""
        echo "Root Application:"
        kubectl get application root -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null && echo "" || echo "Sync status unknown"
        echo "Health: $(kubectl get application root -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null)"
        echo ""
    fi

    # Check infrastructure app
    if kubectl get application infrastructure -n argocd >/dev/null 2>&1; then
        echo "Infrastructure Application:"
        echo "Sync: $(kubectl get application infrastructure -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null)"
        echo "Health: $(kubectl get application infrastructure -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null)"
        echo ""
    fi

    echo "=== Refreshing in 5 seconds... (Ctrl+C to stop) ==="
    sleep 5
done
