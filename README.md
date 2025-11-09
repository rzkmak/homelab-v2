# My Homelab

This repository contains the infrastructure and deployment configurations for my homelab.

## Hardware

*   **Server:** Dell OptiPlex 3070 Micro
*   **CPU:** Intel Core i5-8500T
*   **Memory:** 32GB RAM

## Core Components

*   **Kubernetes:** k3s v1.28.5+k3s1 (Kubernetes 1.28.5)
*   **GitOps:** ArgoCD
*   **Ingress:** Traefik
*   **Certificate Management:** cert-manager
*   **Secure Tunneling:** (To be determined: Cloudflare Tunnel, Tailscale, etc.)
*   **Observability:**
    *   **Logs:** Quickwit (storage), Vector (collection)
    *   **Metrics:** Prometheus (kube-prometheus-stack)
    *   **Visualization:** Grafana
*   **Artifact Hosting:** Gitea

> 📋 See [VERSIONS.md](VERSIONS.md) for detailed version information and compatibility matrix.

## Goals

*   Learn infrastructure management best practices.
*   Gain experience with Kubernetes, GitOps, and observability.
*   Host and manage personal applications.

## 📚 Documentation

**Before you start, please review:**

1. **[DEPLOYMENT_BLUEPRINT.md](DEPLOYMENT_BLUEPRINT.md)** - 📋 Complete deployment overview and guide ⭐ **START HERE**
2. **[PRE_FLIGHT_CHECKLIST.md](PRE_FLIGHT_CHECKLIST.md)** - ✅ Pre-deployment checklist
3. **[FILE_MANIFEST.md](FILE_MANIFEST.md)** - 📄 Complete list of all files created
4. **[SETUP.md](SETUP.md)** - 📖 Detailed step-by-step walkthrough
5. **[VERSIONS.md](VERSIONS.md)** - 🔢 Component version compatibility matrix
6. **[kubernetes/secrets/README.md](kubernetes/secrets/README.md)** - 🔐 Secrets management guide

## Important: Secrets Management

**This repository is PUBLIC.** No secrets are committed to git. We use:

- **Sealed Secrets** (Bitnami) for encrypted secrets that can be safely stored in git
- **Manual secret creation** for secrets not stored in git
- **First-run configuration** for some services (e.g., Gitea)

See [kubernetes/secrets/README.md](kubernetes/secrets/README.md) for complete secrets management documentation.

## Quick Start

### Prerequisites

*   k3s cluster installed and running
*   `kubectl` configured to access your cluster
*   `make` installed (optional, for convenience commands)
*   `kubeseal` CLI (for managing secrets)

### Deployment

1. **Bootstrap ArgoCD and all applications:**
   ```bash
   make bootstrap
   ```

   This will:
   - Install ArgoCD
   - Deploy the root application (app-of-apps pattern)
   - Automatically sync all infrastructure and applications

2. **Access ArgoCD dashboard:**
   ```bash
   make password    # Get the admin password
   make dashboard   # Port-forward to localhost:8080
   ```

3. **Access Grafana:**
   ```bash
   make grafana     # Port-forward to localhost:3000
   ```

### Manual Installation

If you prefer to install step-by-step:

```bash
# 1. Install ArgoCD
make install-argocd

# 2. Apply root application
make apply-root

# 3. Check status
make status
```

## Repository Structure

```
kubernetes/
├── bootstrap/          # ArgoCD installation and root application
├── apps/              # ArgoCD Application definitions (app-of-apps)
├── infra/             # Infrastructure components
│   ├── traefik.yaml
│   ├── cert-manager.yaml
│   ├── sealed-secrets.yaml
│   ├── kube-prometheus-stack.yaml
│   ├── vector.yaml
│   ├── quickwit.yaml
│   └── gitea.yaml
└── secrets/           # Secrets management (NEVER commit plain secrets!)
    ├── README.md      # Secrets documentation
    └── templates/     # Secret templates (examples only)
```

## Deployed Applications

### Infrastructure
- **Traefik** - Ingress controller
- **cert-manager** - Certificate management
- **Sealed Secrets** - Encrypted secrets management
- **Gitea** - Git hosting and artifact repository

### Observability
- **Prometheus** - Metrics collection and alerting
- **Grafana** - Visualization and dashboards
- **Quickwit** - Cloud-native search engine for logs
- **Vector** - High-performance observability data pipeline

### Access URLs

**Port-forwarded (from main PC):**
- ArgoCD: `https://localhost:8080` (run `make dashboard`)
- Grafana: `http://localhost:3000` (run `make grafana`)

**Direct access (after configuring DNS/hosts file):**
- Grafana: `http://grafana.homelab.local`
- Gitea: `http://gitea.homelab.local`
- Quickwit UI: `http://quickwit.homelab.local`
- Traefik Dashboard: `https://traefik.homelab.local`

**Configure /etc/hosts on your main PC:**
```bash
sudo sh -c 'echo "192.168.0.210 grafana.homelab.local gitea.homelab.local quickwit.homelab.local traefik.homelab.local" >> /etc/hosts'
```

---

## Installation Details

### k3s Installation (Remote Server)

**Server Details:**
- Host: `rizki@192.168.0.210`
- SSH authentication from main PC

#### 1. Configure passwordless sudo (recommended)

SSH into your server:
```bash
ssh rizki@192.168.0.210
```

Configure passwordless sudo for easier k3s management:
```bash
echo "rizki ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/rizki
sudo chmod 0440 /etc/sudoers.d/rizki
```

#### 2. Install k3s on the remote server

Install k3s v1.28.5+k3s1 with Kubernetes 1.28.5 (disable built-in Traefik since we'll manage it via GitOps):
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 sh -s - --disable traefik
```

Check the installation:
```bash
sudo k3s kubectl get nodes
sudo k3s kubectl version
```

You should see Server Version: v1.28.5+k3s1

#### 3. Configure kubectl on your main PC

Get the kubeconfig from the remote server:
```bash
ssh rizki@192.168.0.210 "sudo cat /etc/rancher/k3s/k3s.yaml" > ~/.kube/k3s-config
```

Edit the config to use the remote server IP:
```bash
sed -i '' 's/127.0.0.1/192.168.0.210/g' ~/.kube/k3s-config
```

Set the KUBECONFIG environment variable:
```bash
export KUBECONFIG=~/.kube/k3s-config
```

Or merge it with your existing kubeconfig:
```bash
KUBECONFIG=~/.kube/config:~/.kube/k3s-config kubectl config view --flatten > ~/.kube/config-merged
mv ~/.kube/config-merged ~/.kube/config
kubectl config use-context default
```

Verify connection:
```bash
kubectl get nodes
```

#### 4. Helper Command

Use the Makefile to automatically fetch and configure kubeconfig:
```bash
make setup-kubeconfig
```

**Note:** The `make setup-kubeconfig` command requires passwordless sudo on the remote server (configured in step 1).