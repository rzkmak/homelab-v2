# Deployment Blueprint - Complete Overview

**Status:** ✅ Ready for Review
**Repository State:** Safe for PUBLIC use (no secrets committed)
**Target:** Remote k3s cluster at rizki@192.168.0.210
**Kubernetes Version:** v1.28.5+k3s1 (Kubernetes 1.28.5) - ✅ CONFIRMED INSTALLED

---

## 📋 Table of Contents

1. [Files Created Summary](#files-created-summary)
2. [Architecture Overview](#architecture-overview)
3. [Pre-Flight Checklist](#pre-flight-checklist)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Secrets Management](#secrets-management)
7. [Access Information](#access-information)

---

## Files Created Summary

### Bootstrap (ArgoCD Installation)
```
kubernetes/bootstrap/
├── argocd-namespace.yaml          # ArgoCD namespace
├── argocd-install.yaml            # Installation notes
├── root-application.yaml          # Root app-of-apps
└── README.md                      # Bootstrap documentation
```

### Applications (App-of-Apps)
```
kubernetes/apps/
├── infra-apps.yaml                # Infrastructure application
└── README.md                      # Apps documentation
```

### Infrastructure Components
```
kubernetes/infra/
├── traefik.yaml                   # Ingress controller (Helm: 26.0.0)
├── cert-manager.yaml              # Certificate management (Helm: v1.13.3)
├── sealed-secrets.yaml            # Secret encryption (Helm: 2.15.0)
├── kube-prometheus-stack.yaml     # Prometheus + Grafana (Helm: 56.0.0)
├── vector.yaml                    # Log collection (Helm: 0.35.0)
├── quickwit.yaml                  # Log storage (App)
├── quickwit-manifests/
│   ├── configmap.yaml            # Quickwit config + index schema
│   ├── pvc.yaml                  # 20Gi storage for logs
│   ├── deployment.yaml           # Quickwit server (image: 0.8.1)
│   ├── service.yaml              # Quickwit services
│   ├── ingress.yaml              # External access
│   └── README.md                 # Quickwit documentation
├── grafana-quickwit-datasource.yaml  # Grafana datasource config
├── gitea.yaml                    # Git hosting (Helm: 10.1.0)
└── README.md                     # Infrastructure documentation
```

### Secrets Management
```
kubernetes/secrets/
├── README.md                      # Comprehensive secrets guide
└── templates/
    └── grafana-admin-credentials.yaml.template  # Secret template
```

### Scripts & Automation
```
scripts/
└── check-deployment.sh            # Deployment verification script

Makefile                           # Automation commands
.gitignore                         # Protects secrets from commit
```

### Documentation
```
README.md                          # Main documentation
SETUP.md                           # Step-by-step setup guide
VERSIONS.md                        # Component version matrix
DEPLOYMENT_BLUEPRINT.md            # This file
```

---

## Architecture Overview

### GitOps Flow
```
┌─────────────────────────────────────────────────────────┐
│  GitHub Repository (PUBLIC - No Secrets)                │
│  https://github.com/rzkmak/homelab-v2                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ ArgoCD pulls manifests
                     ↓
┌─────────────────────────────────────────────────────────┐
│  Remote k3s Cluster (rizki@192.168.0.210)              │
│  Kubernetes v1.28.5+k3s1                                │
│                                                          │
│  ArgoCD (app-of-apps pattern)                           │
│    └── Infrastructure                                   │
│         ├── Traefik (Ingress)                          │
│         ├── cert-manager (SSL/TLS)                     │
│         ├── Sealed Secrets (Secret encryption)         │
│         ├── kube-prometheus-stack (Metrics + Grafana)  │
│         ├── Vector (Log collection)                    │
│         ├── Quickwit (Log storage)                     │
│         └── Gitea (Git hosting)                        │
└─────────────────────────────────────────────────────────┘
```

### Observability Stack
```
┌──────────────────┐
│ Kubernetes Pods  │ (stdout/stderr)
└────────┬─────────┘
         │
         ↓
┌──────────────────┐
│ Vector DaemonSet │ (Collects + Enriches logs)
└────────┬─────────┘
         │
         ↓
┌──────────────────┐
│ Quickwit         │ (Stores + Indexes logs)
└────────┬─────────┘
         │
         ↓
┌──────────────────┐         ┌──────────────────┐
│ Grafana          │ ←───────│ Prometheus       │
│ (Visualization)  │         │ (Metrics)        │
└──────────────────┘         └──────────────────┘
```

### Secrets Management
```
┌─────────────────────────────────────────────────────────┐
│  Developer Machine                                      │
│                                                          │
│  1. Create plain secret (LOCAL ONLY - not committed)   │
│  2. Apply directly to cluster (Option A)                │
│     OR                                                   │
│  3. Seal with kubeseal → commit encrypted (Option B)   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│  Kubernetes Cluster                                     │
│                                                          │
│  Sealed Secrets Controller                              │
│  - Decrypts SealedSecrets → Creates plain Secrets      │
│  - Applications use plain Secrets                       │
└─────────────────────────────────────────────────────────┘
```

---

## Pre-Flight Checklist

### ✅ Completed
- [x] k3s v1.28.5+k3s1 installed on rizki@192.168.0.210
- [x] All manifests created (no hardcoded secrets)
- [x] .gitignore configured to prevent secret commits
- [x] Repository safe for public use

### 🔲 Before Deployment
- [ ] Passwordless sudo configured on remote server
- [ ] kubectl access configured from main PC
- [ ] KUBECONFIG environment variable set
- [ ] Connection to cluster verified

### 🔲 After Infrastructure Deployment
- [ ] ArgoCD installed and accessible
- [ ] Sealed Secrets controller running
- [ ] All applications synced and healthy

### 🔲 After Secrets Configuration
- [ ] Grafana admin credentials created
- [ ] Gitea initial setup completed

---

## Deployment Steps

### Phase 1: Prerequisites (BEFORE bootstrap)

#### Step 1.1: Configure Passwordless Sudo (Optional but Recommended)

**From your main PC:**
```bash
make setup-passwordless-sudo
```

This prompts for password once, then configures passwordless sudo for `rizki` user.

**Alternative (Manual):**
```bash
ssh rizki@192.168.0.210
echo "rizki ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/rizki
sudo chmod 0440 /etc/sudoers.d/rizki
exit
```

#### Step 1.2: Configure kubectl

```bash
# Fetch kubeconfig from remote server
make setup-kubeconfig

# Set environment variable (add to ~/.zshrc or ~/.bashrc for persistence)
export KUBECONFIG=~/.kube/k3s-config

# Verify connection
make check-connection
```

**Expected Output:**
```
Kubernetes control plane is running at https://192.168.0.210:6443
NAME                 STATUS   ROLES                  AGE   VERSION
<hostname>           Ready    control-plane,master   Xm    v1.28.5+k3s1
```

---

### Phase 2: Bootstrap Infrastructure

#### Step 2.1: Deploy ArgoCD and Root Application

```bash
make bootstrap
```

**What this does:**
1. Creates `argocd` namespace
2. Installs ArgoCD from official manifest
3. Waits for ArgoCD server to be ready
4. Applies root-application.yaml

**Expected Duration:** 2-3 minutes

#### Step 2.2: Wait for Applications to be Created

```bash
# Wait for ArgoCD to process the app-of-apps structure
sleep 30

# Check applications
make check-apps
```

**Expected Output:**
```
ArgoCD Applications:
NAME              SYNC STATUS   HEALTH STATUS
root              Synced        Healthy
infrastructure    Synced        Healthy
sealed-secrets    Syncing       Progressing
traefik           Syncing       Progressing
cert-manager      Syncing       Progressing
...
```

#### Step 2.3: Monitor Application Sync

```bash
# Watch applications sync (interactive)
make wait-for-apps
```

**Press Ctrl+C when all applications show:**
- SYNC STATUS: Synced
- HEALTH STATUS: Healthy

**Expected Duration:** 5-10 minutes

---

### Phase 3: Secrets Configuration

#### Step 3.1: Install kubeseal CLI

**macOS:**
```bash
brew install kubeseal
```

**Linux:**
```bash
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar xfz kubeseal-0.24.0-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

#### Step 3.2: Create Grafana Admin Secret

**Option A: Direct Secret Creation (Recommended for homelab)**

```bash
kubectl create secret generic grafana-admin-credentials \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=CHANGE_TO_SECURE_PASSWORD \
  --namespace=monitoring
```

**Option B: Using Sealed Secrets (For git storage)**

See detailed instructions in `kubernetes/secrets/README.md`

#### Step 3.3: Restart Grafana (to pick up secret)

```bash
kubectl rollout restart deployment kube-prometheus-stack-grafana -n monitoring
```

#### Step 3.4: Configure Gitea (First Access)

Gitea has NO default admin account (security best practice).

1. Visit http://gitea.homelab.local (after DNS/hosts configured)
2. Complete installation wizard
3. Create your admin account

---

### Phase 4: Verification

#### Step 4.1: Check All Pods

```bash
kubectl get pods -A
```

**All pods should be Running or Completed.**

#### Step 4.2: Check ArgoCD Applications

```bash
make status
```

**All should show:**
- SYNC STATUS: Synced
- HEALTH STATUS: Healthy

#### Step 4.3: Access Services

**Get ArgoCD Password:**
```bash
make password
```

**ArgoCD Dashboard:**
```bash
make dashboard
# Access: https://localhost:8080
# Username: admin
# Password: (from previous command)
```

**Grafana:**
```bash
make grafana
# Access: http://localhost:3000
# Username: admin
# Password: (what you set in Phase 3)
```

---

## Post-Deployment Verification

### Infrastructure Checklist

```bash
# Sealed Secrets
kubectl get deployment -n kube-system -l app.kubernetes.io/name=sealed-secrets
# Expected: 1/1 Ready

# Traefik
kubectl get pods -n traefik
# Expected: DaemonSet pods running on all nodes

# cert-manager
kubectl get pods -n cert-manager
# Expected: 3 pods (controller, webhook, cainjector) Running

# Prometheus Stack
kubectl get pods -n monitoring | grep prometheus
# Expected: Multiple prometheus pods Running

# Vector
kubectl get pods -n monitoring | grep vector
# Expected: DaemonSet pods on all nodes

# Quickwit
kubectl get pods -n monitoring | grep quickwit
# Expected: 1 pod Running

# Gitea
kubectl get pods -n gitea
# Expected: 1 pod Running
```

### Test Log Flow

```bash
# Check Vector is collecting logs
kubectl logs -n monitoring daemonset/vector --tail=50

# Check Quickwit is receiving logs
kubectl logs -n monitoring deployment/quickwit --tail=50

# Access Quickwit UI
kubectl port-forward -n monitoring svc/quickwit-searcher 7280:7280
# Open: http://localhost:7280
```

---

## Secrets Management

### ⚠️ IMPORTANT: This repository is PUBLIC

**Never commit:**
- ❌ Plain Secret YAML files
- ❌ Password files
- ❌ Private keys
- ❌ `.env` files with credentials

**Safe to commit:**
- ✅ `*-sealed.yaml` (encrypted secrets)
- ✅ Templates (`.template` files)
- ✅ Documentation

### Current Secret Requirements

| Secret Name | Namespace | Required By | Status |
|------------|-----------|-------------|---------|
| `grafana-admin-credentials` | monitoring | Grafana | ⚠️ YOU MUST CREATE |
| Gitea admin | N/A | Gitea | ℹ️ Web UI setup |

### Creating Additional Secrets

See comprehensive guide: `kubernetes/secrets/README.md`

---

## Access Information

### Port-Forwarded Access (from main PC)

| Service | Command | URL | Credentials |
|---------|---------|-----|-------------|
| ArgoCD | `make dashboard` | https://localhost:8080 | admin / `make password` |
| Grafana | `make grafana` | http://localhost:3000 | admin / YOUR_PASSWORD |
| Quickwit | `kubectl port-forward -n monitoring svc/quickwit-searcher 7280:7280` | http://localhost:7280 | None |

### Direct Access (requires DNS/hosts configuration)

**Configure /etc/hosts on main PC:**
```bash
sudo sh -c 'echo "192.168.0.210 grafana.homelab.local gitea.homelab.local quickwit.homelab.local traefik.homelab.local" >> /etc/hosts'
```

**Access URLs:**
- Grafana: http://grafana.homelab.local
- Gitea: http://gitea.homelab.local
- Quickwit: http://quickwit.homelab.local
- Traefik: https://traefik.homelab.local

---

## Component Versions

| Component | Version | Type | Namespace |
|-----------|---------|------|-----------|
| k3s | v1.28.5+k3s1 | Distribution | - |
| ArgoCD | stable | Manifest | argocd |
| Traefik | 26.0.0 | Helm | traefik |
| cert-manager | v1.13.3 | Helm | cert-manager |
| Sealed Secrets | 2.15.0 | Helm | kube-system |
| kube-prometheus-stack | 56.0.0 | Helm | monitoring |
| Vector | 0.35.0 | Helm | monitoring |
| Quickwit | 0.8.1 | Manifests | monitoring |
| Gitea | 10.1.0 | Helm | gitea |

**All components verified compatible with Kubernetes 1.28.5 ✅**

See detailed compatibility matrix: `VERSIONS.md`

---

## Troubleshooting Quick Reference

### Issue: "sealed-secrets-controller not found"
**Cause:** Tried to wait before ArgoCD synced it
**Solution:** `make wait-for-apps` then verify it's ready

### Issue: Can't connect to cluster
**Solution:** `make setup-kubeconfig && export KUBECONFIG=~/.kube/k3s-config`

### Issue: Grafana shows "Invalid username or password"
**Cause:** Secret not created or not picked up
**Solution:** Create secret, then `kubectl rollout restart deployment kube-prometheus-stack-grafana -n monitoring`

### Issue: Applications stuck in "Progressing"
**Solution:**
```bash
kubectl describe application <app-name> -n argocd
kubectl logs -n argocd deployment/argocd-application-controller
```

**See full troubleshooting guide:** `SETUP.md` → Troubleshooting section

---

## Summary

### What You Have
✅ Complete GitOps infrastructure configuration
✅ Public-safe repository (no secrets)
✅ Modern observability stack (Vector + Quickwit)
✅ Automated deployment via ArgoCD
✅ Sealed Secrets for secret management
✅ All components compatible with k8s 1.28.5

### What You Need to Do
1. ✅ k3s installed (DONE)
2. Configure kubectl access
3. Run `make bootstrap`
4. Wait for applications to sync
5. Create Grafana secret
6. Configure Gitea via web UI
7. Enjoy your homelab! 🎉

### Estimated Total Time
- Prerequisites: 5 minutes
- Bootstrap: 3 minutes
- App sync wait: 10 minutes
- Secrets configuration: 2 minutes
- **Total: ~20 minutes**

---

## Ready to Deploy?

Review this blueprint, then follow the steps in order. Each phase must complete before moving to the next.

**Start here:** Phase 1, Step 1.1 → Configure Passwordless Sudo

**Questions?** See `SETUP.md` for detailed walkthrough or `kubernetes/secrets/README.md` for secrets management.

**Good luck!** 🚀
