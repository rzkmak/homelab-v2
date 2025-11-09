# File Manifest - Complete Repository Structure

**Generated:** For homelab-v2 deployment
**Purpose:** Complete list of all files created for review before deployment

---

## Repository Root Files

```
.
├── .gitignore                          # Protects secrets from being committed
├── Makefile                            # Automation commands for deployment
├── README.md                           # Main repository documentation
├── SETUP.md                            # Detailed step-by-step setup guide
├── VERSIONS.md                         # Component version compatibility matrix
├── DEPLOYMENT_BLUEPRINT.md             # Complete deployment overview (THIS IS YOUR MAIN GUIDE)
├── PRE_FLIGHT_CHECKLIST.md            # Pre-deployment checklist
├── FILE_MANIFEST.md                    # This file
└── temporary.md                        # (ignored by git)
```

---

## Kubernetes Manifests

### Bootstrap (ArgoCD Installation)

**Location:** `kubernetes/bootstrap/`

| File | Purpose | Type |
|------|---------|------|
| `argocd-namespace.yaml` | Creates argocd namespace | Kubernetes Namespace |
| `argocd-install.yaml` | Installation notes and reference | Documentation |
| `root-application.yaml` | Root Application (app-of-apps) | ArgoCD Application |
| `README.md` | Bootstrap documentation | Documentation |

**Key Configuration:**
- Repository: `https://github.com/rzkmak/homelab-v2.git`
- Branch: `main`
- Path: `kubernetes/apps`

---

### Applications (App-of-Apps Layer)

**Location:** `kubernetes/apps/`

| File | Purpose | Type |
|------|---------|------|
| `infra-apps.yaml` | Infrastructure Application (creates all infra components) | ArgoCD Application |
| `README.md` | Application layer documentation | Documentation |

**Key Configuration:**
- Points to: `kubernetes/infra/`
- Auto-sync: Enabled
- Self-heal: Enabled

---

### Infrastructure Components

**Location:** `kubernetes/infra/`

#### Core Infrastructure

| File | Component | Version | Namespace | Description |
|------|-----------|---------|-----------|-------------|
| `traefik.yaml` | Traefik | 26.0.0 | traefik | Ingress controller |
| `cert-manager.yaml` | cert-manager | v1.13.3 | cert-manager | SSL certificate management |
| `sealed-secrets.yaml` | Sealed Secrets | 2.15.0 | kube-system | Secret encryption |

#### Observability Stack

| File | Component | Version | Namespace | Description |
|------|-----------|---------|-----------|-------------|
| `kube-prometheus-stack.yaml` | Prometheus + Grafana | 56.0.0 | monitoring | Metrics & visualization |
| `vector.yaml` | Vector | 0.35.0 | monitoring | Log collection (DaemonSet) |
| `quickwit.yaml` | Quickwit | 0.8.1 | monitoring | Log storage & search |
| `grafana-quickwit-datasource.yaml` | ConfigMap | - | monitoring | Grafana datasource for Quickwit |

#### Development Tools

| File | Component | Version | Namespace | Description |
|------|-----------|---------|-----------|-------------|
| `gitea.yaml` | Gitea | 10.1.0 | gitea | Self-hosted Git service |

#### Documentation

| File | Purpose |
|------|---------|
| `README.md` | Infrastructure components documentation |

---

### Quickwit Detailed Manifests

**Location:** `kubernetes/infra/quickwit-manifests/`

| File | Purpose | Type |
|------|---------|------|
| `configmap.yaml` | Quickwit config + index schema | ConfigMap (2 configs) |
| `pvc.yaml` | 20Gi storage for logs | PersistentVolumeClaim |
| `deployment.yaml` | Quickwit server deployment | Deployment |
| `service.yaml` | Internal services (searcher, indexer) | 2 Services |
| `ingress.yaml` | External access at quickwit.homelab.local | Ingress |
| `README.md` | Quickwit usage guide | Documentation |

**Index Schema Fields:**
- `timestamp` (datetime) - Log timestamp
- `level` (text) - Log level
- `message` (text) - Log message (full-text searchable)
- `namespace` (text) - Kubernetes namespace
- `pod_name` (text) - Pod name
- `container_name` (text) - Container name
- `node_name` (text) - Node name
- `cluster` (text) - Cluster identifier

---

### Secrets Management

**Location:** `kubernetes/secrets/`

| File | Purpose | Safe to Commit? |
|------|---------|-----------------|
| `README.md` | Comprehensive secrets management guide | ✅ Yes |
| `templates/grafana-admin-credentials.yaml.template` | Example secret template | ✅ Yes |

**Security:**
- ❌ NO plain secrets committed
- ✅ Sealed secrets allowed (`*-sealed.yaml`)
- ✅ Templates allowed (`.template`)
- `.gitignore` enforces this

---

### Scripts

**Location:** `scripts/`

| File | Purpose | Usage |
|------|---------|-------|
| `check-deployment.sh` | Deployment verification script | `bash scripts/check-deployment.sh` |

---

## Configuration Files

### Makefile Targets

**Location:** `./Makefile`

| Target | Description |
|--------|-------------|
| `help` | Show all available commands |
| `setup-passwordless-sudo` | Configure passwordless sudo on remote server |
| `setup-kubeconfig` | Fetch kubeconfig from remote k3s server |
| `check-connection` | Test cluster connectivity |
| `bootstrap` | Install ArgoCD + deploy all apps |
| `check-apps` | Check application status |
| `wait-for-apps` | Watch applications sync (interactive) |
| `status` | ArgoCD application status |
| `dashboard` | Port-forward ArgoCD dashboard |
| `grafana` | Port-forward Grafana |
| `password` | Get ArgoCD admin password |
| `ssh-server` | SSH to k3s server |
| `clean` | Remove everything (dangerous!) |

### .gitignore Rules

**Location:** `./.gitignore`

**Protected from commit:**
- `kubernetes/secrets/*.yaml` (except `*-sealed.yaml`)
- `*.secret.yaml`
- `*-credentials.yaml`
- `/tmp/*-secret.yaml`
- `sealed-secrets-key-backup.yaml`

**Allowed:**
- `*-sealed.yaml` (encrypted secrets)
- `*.template` files
- `README.md` files

---

## Documentation Files

| File | Purpose | Read Before |
|------|---------|-------------|
| `README.md` | Repository overview | Starting |
| `DEPLOYMENT_BLUEPRINT.md` | **MAIN DEPLOYMENT GUIDE** | Deploying |
| `PRE_FLIGHT_CHECKLIST.md` | Pre-deployment checklist | Deploying |
| `SETUP.md` | Step-by-step walkthrough | Deploying |
| `VERSIONS.md` | Version compatibility matrix | Understanding |
| `FILE_MANIFEST.md` | This file - complete file list | Reviewing |
| `kubernetes/secrets/README.md` | Secrets management guide | Creating secrets |
| `kubernetes/bootstrap/README.md` | Bootstrap documentation | Understanding ArgoCD |
| `kubernetes/apps/README.md` | App-of-apps documentation | Understanding GitOps |
| `kubernetes/infra/README.md` | Infrastructure docs | Understanding components |
| `kubernetes/infra/quickwit-manifests/README.md` | Quickwit usage guide | Using logs |

---

## File Count Summary

```
Total Kubernetes Manifests: 22 files
  ├── Bootstrap: 4 files
  ├── Applications: 2 files
  ├── Infrastructure: 10 files
  ├── Quickwit manifests: 6 files
  └── Secrets: 0 committed (templates only)

Documentation: 10 files
Scripts: 1 file
Configuration: 2 files (.gitignore, Makefile)

Total: 35+ files
```

---

## Critical Files to Review

### MUST REVIEW before deployment:

1. **`DEPLOYMENT_BLUEPRINT.md`** - Complete deployment overview
2. **`PRE_FLIGHT_CHECKLIST.md`** - Pre-deployment checklist
3. **`kubernetes/bootstrap/root-application.yaml`** - Verify repository URL
4. **`kubernetes/apps/infra-apps.yaml`** - Verify repository URL
5. **`kubernetes/secrets/README.md`** - Secrets management guide

### Verify These Values:

**Repository URL (appears in 2 files):**
- `kubernetes/bootstrap/root-application.yaml:11`
- `kubernetes/apps/infra-apps.yaml:11`
- Should be: `https://github.com/rzkmak/homelab-v2.git`

**Target Revision:**
- All applications use `targetRevision: main`

**Server Details:**
- Remote: `rizki@192.168.0.210`
- IP: `192.168.0.210`

---

## Security Review

### ✅ Safe for Public Repository

**No secrets committed:**
- ❌ No hardcoded passwords
- ❌ No API keys
- ❌ No private keys
- ❌ No credential files

**Secrets management:**
- ✅ Grafana: Uses `existingSecret` reference
- ✅ Gitea: First-run web UI configuration
- ✅ Sealed Secrets: Controller for encrypted secrets
- ✅ .gitignore: Prevents accidental commits

**Protected by .gitignore:**
- All `*.yaml` files in `kubernetes/secrets/` (except sealed)
- All `*.secret.yaml` files
- All credential files

---

## Next Steps

After reviewing all files:

1. ✅ **Review this manifest** - Understand what each file does
2. ✅ **Check `PRE_FLIGHT_CHECKLIST.md`** - Complete the checklist
3. ✅ **Read `DEPLOYMENT_BLUEPRINT.md`** - Your main deployment guide
4. ✅ **Verify repository URLs** - Make sure they're correct
5. ✅ **Understand secrets workflow** - Read `kubernetes/secrets/README.md`
6. 🚀 **Ready to deploy** - Follow `DEPLOYMENT_BLUEPRINT.md` Phase 1

---

## Questions?

- **General setup:** See `README.md`
- **Step-by-step guide:** See `SETUP.md`
- **Complete blueprint:** See `DEPLOYMENT_BLUEPRINT.md`
- **Secrets management:** See `kubernetes/secrets/README.md`
- **Component versions:** See `VERSIONS.md`
- **Troubleshooting:** See `SETUP.md` → Troubleshooting section

---

**All files reviewed and ready for deployment! 🎉**
