# Pre-Flight Checklist

Complete this checklist **BEFORE** running any deployment commands.

---

## ☑️ Remote Server Setup

- [ ] **k3s installed** on rizki@192.168.0.210
  ```bash
  ssh rizki@192.168.0.210 "sudo k3s kubectl version"
  # Should show: v1.28.5+k3s1
  ```

- [ ] **Passwordless sudo configured** (optional but recommended)
  ```bash
  ssh rizki@192.168.0.210 "sudo whoami"
  # Should NOT ask for password
  ```

---

## ☑️ Local Machine Setup

- [ ] **kubectl installed**
  ```bash
  kubectl version --client
  ```

- [ ] **make installed**
  ```bash
  make --version
  ```

- [ ] **SSH access to remote server works**
  ```bash
  ssh rizki@192.168.0.210 echo "Connected"
  # Should print: Connected
  ```

---

## ☑️ Repository Review

- [ ] **Review all configuration files** in:
  - [ ] `kubernetes/bootstrap/` - ArgoCD installation
  - [ ] `kubernetes/apps/` - App-of-apps structure
  - [ ] `kubernetes/infra/` - Infrastructure components
  - [ ] `kubernetes/secrets/` - Secrets documentation

- [ ] **Verify repository URLs** are correct:
  - [ ] `kubernetes/bootstrap/root-application.yaml:11`
  - [ ] `kubernetes/apps/infra-apps.yaml:11`
  - [ ] Should be: `https://github.com/rzkmak/homelab-v2.git`

- [ ] **Read documentation**:
  - [ ] `README.md` - Overview
  - [ ] `DEPLOYMENT_BLUEPRINT.md` - Complete blueprint
  - [ ] `SETUP.md` - Step-by-step guide
  - [ ] `kubernetes/secrets/README.md` - Secrets management

---

## ☑️ Secrets Preparation

- [ ] **Decide on Grafana admin password**
  - Minimum 16 characters
  - Use a password manager
  - Write it down: ________________

- [ ] **Decide on Gitea admin username**
  - Will be configured on first web UI access
  - Write it down: ________________

- [ ] **kubeseal CLI ready** (if using Sealed Secrets)
  ```bash
  kubeseal --version
  # OR
  brew install kubeseal  # macOS
  ```

---

## ☑️ Network Configuration

- [ ] **Plan for service access** - Choose one:
  - [ ] **Option A:** Port-forwarding only (simpler)
  - [ ] **Option B:** Add entries to /etc/hosts (direct access)
    ```
    192.168.0.210 grafana.homelab.local gitea.homelab.local quickwit.homelab.local traefik.homelab.local
    ```

---

## ☑️ Understanding

- [ ] **Understand the deployment will**:
  - Install ArgoCD
  - Deploy 7 infrastructure components
  - Create ~30+ pods across multiple namespaces
  - Require ~10 minutes to fully sync
  - Use ~4-6GB RAM on the server

- [ ] **Know how to access help**:
  - `make help` - Show all commands
  - `SETUP.md` - Step-by-step guide
  - `DEPLOYMENT_BLUEPRINT.md` - Complete overview

---

## ☑️ Final Check

- [ ] **Cluster accessible from main PC**
  ```bash
  export KUBECONFIG=~/.kube/k3s-config
  make check-connection
  ```

- [ ] **No uncommitted changes** (if making modifications)
  ```bash
  git status
  ```

- [ ] **You have time** for the full deployment (~20 minutes)

---

## ✅ Ready to Deploy!

If all checkboxes are checked, proceed to:

**Next Step:** See `DEPLOYMENT_BLUEPRINT.md` → Deployment Steps → Phase 1

Or run:
```bash
make setup-kubeconfig
export KUBECONFIG=~/.kube/k3s-config
make bootstrap
```

---

## Emergency Stop

If you need to stop the deployment:

```bash
# Stop watching applications
Ctrl+C

# Remove ArgoCD (WARNING: Deletes everything)
make clean
```

This will remove ArgoCD and all managed applications.
