# Infrastructure

This directory contains ArgoCD Application manifests for core infrastructure components.

## Components

### Ingress & Networking

#### Traefik
- **Purpose:** Ingress controller and reverse proxy
- **Namespace:** `traefik`
- **Note:** k3s comes with Traefik pre-installed. This manifest is provided if you want to manage it via GitOps instead. You may need to disable the built-in Traefik when installing k3s with: `--disable traefik`

#### Cert-Manager
- **Purpose:** Automatic SSL/TLS certificate management
- **Namespace:** `cert-manager`
- **Features:**
  - Automatic certificate issuance and renewal
  - Support for Let's Encrypt, self-signed, and other issuers
  - Integration with Traefik for automatic HTTPS

#### Sealed Secrets
- **Purpose:** Encrypt secrets for safe storage in git
- **Namespace:** `kube-system`
- **Features:**
  - Encrypts Kubernetes secrets with public key
  - Only cluster can decrypt (has private key)
  - Safe to commit encrypted secrets to git
  - Automatic key rotation

### Observability

#### kube-prometheus-stack
- **Purpose:** Complete metrics monitoring stack
- **Namespace:** `monitoring`
- **Includes:** Prometheus, Grafana, AlertManager, Node Exporter, Kube-state-metrics

#### Quickwit
- **Purpose:** Cloud-native search engine for logs
- **Namespace:** `monitoring`
- **Features:**
  - Fast full-text search on logs
  - Cost-effective storage
  - Elasticsearch-compatible API
  - Web UI for log exploration

#### Vector
- **Purpose:** High-performance observability data pipeline
- **Namespace:** `monitoring`
- **Features:**
  - Collects logs from all Kubernetes nodes
  - Transforms and enriches log data
  - Sends logs to Quickwit for storage and indexing

### Development Tools

#### Gitea
- **Purpose:** Self-hosted Git service
- **Namespace:** `gitea`
- **Features:**
  - Git repository hosting
  - Container registry
  - Package registry

## Usage

These applications are automatically deployed by the `infrastructure` Application defined in `kubernetes/apps/infra-apps.yaml`.

To add new infrastructure components, create new Application manifests in this directory.

## Log Flow

```
Kubernetes Pods → Vector (DaemonSet) → Quickwit → Grafana (visualization)
```

Vector runs on each node, collects logs, enriches them with Kubernetes metadata, and forwards them to Quickwit for indexing and storage.
