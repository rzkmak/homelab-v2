# Secrets Management

This directory contains templates and documentation for managing secrets in the homelab cluster.

## Overview

This repository is designed to be **PUBLIC**, so no secrets are committed to git. Instead, we use:

1. **Bitnami Sealed Secrets** - Encrypt secrets that can be safely stored in git
2. **Manual Secret Creation** - Create secrets directly in the cluster (not stored in git)
3. **First-run Configuration** - Some services (like Gitea) prompt for credentials on first access

## Sealed Secrets Controller

The Sealed Secrets controller is automatically deployed as part of the infrastructure stack. It allows you to:

- Encrypt secrets using a public key
- Store encrypted secrets safely in git
- Controller decrypts them in the cluster

### How It Works

```
1. You create a regular Secret (locally, not committed)
2. You seal it using kubeseal CLI (creates SealedSecret)
3. You commit the SealedSecret to git (safe - only cluster can decrypt)
4. ArgoCD syncs the SealedSecret
5. Sealed Secrets controller decrypts it into a regular Secret
6. Your application uses the Secret
```

## Required Secrets

### 1. Grafana Admin Credentials

**Required by:** kube-prometheus-stack (Grafana)
**Namespace:** monitoring
**Secret name:** `grafana-admin-credentials`

**Option A: Using Sealed Secrets (Recommended for git storage)**

```bash
# 1. Install kubeseal CLI
# macOS
brew install kubeseal

# Linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar xfz kubeseal-0.24.0-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

# 2. Create the secret locally (DO NOT COMMIT THIS FILE)
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

# 3. Seal the secret (this CAN be committed)
kubeseal --format=yaml --cert=pub-cert.pem < /tmp/grafana-secret.yaml > kubernetes/secrets/grafana-admin-credentials-sealed.yaml

# 4. Clean up the plain secret
rm /tmp/grafana-secret.yaml

# 5. Commit the sealed secret
git add kubernetes/secrets/grafana-admin-credentials-sealed.yaml
git commit -m "Add Grafana admin credentials (sealed)"
git push
```

**Option B: Create Secret Directly in Cluster (Not stored in git)**

```bash
kubectl create secret generic grafana-admin-credentials \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=YOUR_SECURE_PASSWORD \
  --namespace=monitoring
```

### 2. Gitea Admin Account

**Required by:** Gitea
**Configuration:** First-run web UI setup

Gitea is configured **without** a default admin account for security. On first access:

1. Visit http://gitea.homelab.local
2. Complete the installation wizard
3. Create your admin account

**No secret needed** - configured through web UI on first run.

## Getting the Sealed Secrets Public Certificate

Before you can create sealed secrets, you need the public certificate from the cluster:

```bash
# Wait for sealed-secrets controller to be ready
kubectl wait --for=condition=available --timeout=300s deployment/sealed-secrets-controller -n kube-system

# Fetch the public certificate
kubeseal --fetch-cert > pub-cert.pem

# Now you can seal secrets using this certificate
```

**Important:**
- The `pub-cert.pem` file can be safely committed to git (it's a public key)
- Only the cluster has the private key to decrypt sealed secrets

## Workflow for Adding New Secrets

### If you want the encrypted secret in git (using Sealed Secrets):

```bash
# 1. Create plain secret (locally only)
cat > /tmp/my-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
  namespace: my-namespace
stringData:
  key1: value1
  key2: value2
EOF

# 2. Seal it
kubeseal --format=yaml --cert=pub-cert.pem < /tmp/my-secret.yaml > kubernetes/secrets/my-secret-sealed.yaml

# 3. Clean up plain secret
rm /tmp/my-secret.yaml

# 4. Apply or commit the sealed secret
kubectl apply -f kubernetes/secrets/my-secret-sealed.yaml
# OR
git add kubernetes/secrets/my-secret-sealed.yaml
git commit -m "Add my-secret (sealed)"
```

### If you don't need it in git:

```bash
# Just create the secret directly
kubectl create secret generic my-secret \
  --from-literal=key1=value1 \
  --from-literal=key2=value2 \
  --namespace=my-namespace
```

## Security Best Practices

1. **Never commit plain secrets** to git
2. **Use sealed secrets** for secrets that need to be in git
3. **Rotate secrets** periodically
4. **Use strong passwords** (20+ characters, random)
5. **Different passwords** for each service
6. **Backup the sealed-secrets key** (stored in cluster):
   ```bash
   kubectl get secret -n kube-system sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml
   # Store this backup securely (NOT in git!)
   ```

## .gitignore

Make sure your `.gitignore` includes:

```gitignore
# Secrets (plain, unsealed)
kubernetes/secrets/*.yaml
!kubernetes/secrets/*-sealed.yaml
!kubernetes/secrets/templates/*.template
!kubernetes/secrets/README.md

# Sealed secrets public cert (can be committed, but optional)
# pub-cert.pem

# Temporary secret files
/tmp/*-secret.yaml
*.secret.yaml
```

## Troubleshooting

### Sealed secret not decrypting

Check the controller logs:
```bash
kubectl logs -n kube-system deployment/sealed-secrets-controller
```

### Secret not found error

Make sure the sealed secret has been applied:
```bash
kubectl get sealedsecrets -n monitoring
kubectl get secrets -n monitoring
```

### Want to view a secret value

```bash
# View secret (base64 encoded)
kubectl get secret grafana-admin-credentials -n monitoring -o yaml

# Decode a specific key
kubectl get secret grafana-admin-credentials -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
```

### Rotate sealed secrets encryption key

The sealed-secrets controller automatically rotates keys every 30 days. Old keys are kept to decrypt existing sealed secrets. To force rotation:

```bash
kubectl delete secret sealed-secrets-key -n kube-system
kubectl delete pod -n kube-system -l app.kubernetes.io/name=sealed-secrets
```

Then re-seal all your secrets with the new public certificate.

## Templates

The `templates/` directory contains example secret templates. Copy and modify them:

```bash
cp kubernetes/secrets/templates/grafana-admin-credentials.yaml.template /tmp/grafana-secret.yaml
# Edit /tmp/grafana-secret.yaml with your values
kubeseal --format=yaml --cert=pub-cert.pem < /tmp/grafana-secret.yaml > kubernetes/secrets/grafana-admin-credentials-sealed.yaml
rm /tmp/grafana-secret.yaml
```

## References

- [Sealed Secrets Documentation](https://github.com/bitnami-labs/sealed-secrets)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Secret Management Best Practices](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
