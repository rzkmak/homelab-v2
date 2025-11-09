# Homelab Setup Guide

This guide walks through the complete setup of your homelab with k3s and ArgoCD.

## Prerequisites

- **Remote Server:** `rizki@192.168.0.210` with SSH access
- **k3s Version:** v1.28.5+k3s1 (Kubernetes 1.28.5)
- **Main PC:** kubectl and make installed
- **Network Requirements:**
  - Main PC can reach remote server at 192.168.0.210 (SSH, kubectl API)
  - Remote server has internet access (to pull container images and helm charts)
  - Remote server can access GitHub (to clone the repository)
  - Port 6443 accessible on remote server (Kubernetes API)

**Notes:**
- The remote k3s server needs to be able to access `https://github.com/rzkmak/homelab-v2.git` to pull manifests. This is already configured correctly in the ArgoCD applications.
- All helm charts in this setup are tested and compatible with Kubernetes 1.28.5
- See [VERSIONS.md](VERSIONS.md) for complete version information and compatibility details

## Step-by-Step Setup

### 1. Configure Passwordless Sudo on Remote Server (Optional but Recommended)

**Option A: Using Makefile (Easiest)**

From your main PC:
```bash
make setup-passwordless-sudo
```

This will prompt for your password once and configure passwordless sudo.

**Option B: Manual Setup**

SSH into the server:
```bash
ssh rizki@192.168.0.210
```

Configure passwordless sudo for your user (makes k3s management easier):
```bash
echo "rizki ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/rizki
sudo chmod 0440 /etc/sudoers.d/rizki
```

Test it:
```bash
sudo whoami  # Should not ask for password
exit
```

**Alternative:** If you prefer not to use passwordless sudo, you'll need to use SSH with `-t` flag for each sudo command:
```bash
ssh -t rizki@192.168.0.210 "sudo k3s kubectl get nodes"
```

### 2. Install k3s on Remote Server

If not already in SSH session, connect:
```bash
ssh rizki@192.168.0.210
```

Install k3s v1.28.5+k3s1 (disable built-in Traefik):
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 sh -s - --disable traefik
```

Verify installation:
```bash
sudo k3s kubectl get nodes
sudo k3s kubectl version
```

You should see:
- Server Version: v1.28.5+k3s1

Exit the SSH session:
```bash
exit
```

### 3. Configure kubectl on Main PC

From your main PC, fetch and configure kubeconfig:
```bash
make setup-kubeconfig
```

This will:
- Fetch kubeconfig from the remote server
- Update the server address to use the remote IP
- Save to `~/.kube/k3s-config`
- Test the connection

Set the KUBECONFIG environment variable:
```bash
export KUBECONFIG=~/.kube/k3s-config
```

Add to your shell profile (`~/.zshrc` or `~/.bashrc`) to make it permanent:
```bash
echo 'export KUBECONFIG=~/.kube/k3s-config' >> ~/.zshrc
source ~/.zshrc
```

Verify connection:
```bash
make check-connection
```

### 4. Deploy Infrastructure (Including Sealed Secrets)

Deploy ArgoCD and the root application:

```bash
make bootstrap
```

This installs ArgoCD and creates the app-of-apps structure. Now wait for ArgoCD to create all applications:

```bash
# Wait a moment for ArgoCD to process the applications
sleep 30

# Check what applications were created
kubectl get applications -n argocd
```

You should see applications like: `root`, `infrastructure`, `sealed-secrets`, `traefik`, etc.

Wait for infrastructure applications to sync and become healthy:

```bash
# Watch applications sync (press Ctrl+C when all show Synced/Healthy)
watch kubectl get applications -n argocd
```

Once sealed-secrets shows as "Synced" and "Healthy", verify the controller is running:

```bash
# Check sealed-secrets deployment
kubectl get deployment -n kube-system | grep sealed

# Wait for it to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment -n kube-system -l app.kubernetes.io/name=sealed-secrets
```

### 5. Configure Secrets

**Important:** This repository is PUBLIC, so no secrets are committed to git.

#### Install kubeseal CLI

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

#### Create Grafana Admin Secret

```bash
# Create secret (locally, not committed)
cat > /tmp/grafana-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin-credentials
  namespace: monitoring
type: Opaque
stringData:
  admin-user: admin
  admin-password: YOUR_SECURE_PASSWORD_HERE
EOF

# Apply it directly to cluster (not stored in git)
kubectl apply -f /tmp/grafana-secret.yaml

# Clean up
rm /tmp/grafana-secret.yaml
```

**Alternative:** Use Sealed Secrets to store encrypted secret in git (see `kubernetes/secrets/README.md`)

#### Configure Gitea Admin Account

Gitea is configured without default credentials. On first access:
1. Visit http://gitea.homelab.local
2. Complete installation wizard
3. Create your admin account

### 6. Wait for Deployment to Complete

Monitor the deployment progress:
```bash
watch kubectl get applications -n argocd
```

Press `Ctrl+C` when all applications show "Healthy" and "Synced".

Check all pods are running:
```bash
kubectl get pods -A
```

### 7. Access the Services

#### ArgoCD

Get the admin password:
```bash
make password
```

Port-forward to access the UI:
```bash
make dashboard
```

Access at: https://localhost:8080
- Username: `admin`
- Password: (from previous command)

#### Grafana

Port-forward to access:
```bash
make grafana
```

Access at: http://localhost:3000
- Username: `admin`
- Password: (what you set in step 3)

#### Configure DNS/Hosts (Optional)

For direct access to services without port-forwarding, add to `/etc/hosts`:
```bash
sudo sh -c 'echo "192.168.0.210 grafana.homelab.local gitea.homelab.local quickwit.homelab.local traefik.homelab.local" >> /etc/hosts'
```

Then access services directly:
- Grafana: http://grafana.homelab.local
- Gitea: http://gitea.homelab.local
- Quickwit: http://quickwit.homelab.local
- Traefik: https://traefik.homelab.local

### 8. Final Verification

Check ArgoCD applications:
```bash
make status
```

All applications should show:
- STATUS: Healthy
- SYNC STATUS: Synced

## Troubleshooting

### "sealed-secrets-controller deployment not found"

This error occurs if you try to wait for sealed-secrets before ArgoCD has synced it.

**Solution:**
```bash
# Check if applications are created
make check-apps

# Watch applications sync (wait until all show Synced/Healthy)
make wait-for-apps

# Then verify sealed-secrets is ready
kubectl get deployment -n kube-system -l app.kubernetes.io/name=sealed-secrets
```

If the sealed-secrets application doesn't exist:
```bash
# Check if infrastructure app is synced
kubectl get application infrastructure -n argocd

# Manually sync if needed
kubectl patch application infrastructure -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### Can't connect to cluster
```bash
make check-connection
```

If this fails, re-fetch the kubeconfig:
```bash
make setup-kubeconfig
```

### ArgoCD not syncing
Check the application details:
```bash
kubectl describe application <app-name> -n argocd
```

Force sync:
```bash
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

### Pods not starting
Check pod logs:
```bash
kubectl logs -n <namespace> <pod-name>
```

Check pod events:
```bash
kubectl describe pod -n <namespace> <pod-name>
```

### SSH into k3s server
```bash
make ssh-server
```

## Next Steps

1. Change default passwords (Grafana, Gitea)
2. Configure SSL certificates with cert-manager
3. Set up secure tunneling (Cloudflare Tunnel or Tailscale)
4. Add your own applications to `kubernetes/apps/`
5. Explore Grafana dashboards for monitoring

## Useful Commands

```bash
make help                      # Show all available commands
make setup-passwordless-sudo   # Configure passwordless sudo on remote server
make setup-kubeconfig          # Fetch kubeconfig from remote server
make check-connection          # Test cluster connectivity
make bootstrap                 # Install ArgoCD and deploy all apps
make status                    # Check ArgoCD application status
make dashboard                 # Access ArgoCD dashboard
make grafana                   # Access Grafana dashboard
make password                  # Get ArgoCD admin password
make ssh-server                # SSH to k3s server
make clean                     # Remove everything (dangerous!)
```
