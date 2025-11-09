# Component Versions

This document lists all software versions used in the homelab setup.

## Kubernetes

- **k3s:** v1.28.5+k3s1
- **Kubernetes:** 1.28.5

## ArgoCD

- **ArgoCD:** stable (installed from official manifest)
  - Installation URL: https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

## Infrastructure Components (Helm Charts)

### Ingress & Networking
- **Traefik:** 26.0.0
  - Repository: https://helm.traefik.io/traefik
  - Kubernetes Compatibility: 1.16+

### Certificate Management
- **cert-manager:** v1.13.3
  - Repository: https://charts.jetstack.io
  - Kubernetes Compatibility: 1.22+

### Secrets Management
- **Sealed Secrets:** 2.15.0
  - Repository: https://bitnami-labs.github.io/sealed-secrets
  - Kubernetes Compatibility: 1.19+
  - Encrypts secrets for safe storage in git

### Git Hosting
- **Gitea:** 10.1.0
  - Repository: https://dl.gitea.com/charts/
  - Kubernetes Compatibility: 1.20+

## Observability Stack (Helm Charts)

### Metrics
- **kube-prometheus-stack:** 56.0.0
  - Repository: https://prometheus-community.github.io/helm-charts
  - Kubernetes Compatibility: 1.19+
  - Includes:
    - Prometheus
    - Grafana
    - AlertManager
    - Node Exporter
    - Kube-state-metrics

### Logging
- **Quickwit:** 0.8.1
  - Deployment: Direct Kubernetes manifests
  - Kubernetes Compatibility: 1.20+
  - Cloud-native search engine for logs
  - Elasticsearch-compatible API

- **Vector:** 0.35.0
  - Repository: https://helm.vector.dev
  - Kubernetes Compatibility: 1.19+
  - High-performance observability data pipeline

## Compatibility Notes

All components listed above are compatible with Kubernetes 1.28.5.

### Tested Compatibility Matrix

| Component | Version | K8s Min Version | K8s 1.28.5 Compatible |
|-----------|---------|-----------------|----------------------|
| Traefik | 26.0.0 | 1.16+ | ✅ |
| cert-manager | v1.13.3 | 1.22+ | ✅ |
| Sealed Secrets | 2.15.0 | 1.19+ | ✅ |
| kube-prometheus-stack | 56.0.0 | 1.19+ | ✅ |
| Quickwit | 0.8.1 | 1.20+ | ✅ |
| Vector | 0.35.0 | 1.19+ | ✅ |
| Gitea | 10.1.0 | 1.20+ | ✅ |

## Updating Versions

To update a component version:

1. Edit the corresponding file in `kubernetes/infra/`
2. Update the `targetRevision` field
3. Commit and push changes
4. ArgoCD will automatically detect and sync the changes

Example:
```yaml
spec:
  source:
    chart: traefik
    targetRevision: 26.0.0  # Update this version
```

## Version Support Policy

- **k3s:** Using specific version v1.28.5+k3s1 for stability
- **Helm Charts:** Using specific versions (not `latest`) for predictable deployments
- **ArgoCD:** Using `stable` branch for latest stable features and security updates

## Checking Installed Versions

### k3s Version
```bash
kubectl version --short
```

### Helm Releases
```bash
helm list -A
```

### ArgoCD Version
```bash
kubectl get deployment argocd-server -n argocd -o jsonpath='{.spec.template.spec.containers[0].image}'
```
