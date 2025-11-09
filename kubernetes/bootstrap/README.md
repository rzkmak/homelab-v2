# Bootstrap

This directory contains the initial setup files for the cluster.

## Installation Order

1. **Create ArgoCD namespace:**
   ```bash
   kubectl apply -f argocd-namespace.yaml
   ```

2. **Install ArgoCD:**
   ```bash
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

3. **Wait for ArgoCD to be ready:**
   ```bash
   kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
   ```

4. **Get the initial admin password:**
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

5. **Port-forward to access ArgoCD UI (optional):**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Then access at https://localhost:8080 (username: `admin`, password from step 4)

6. **Apply the root application (app-of-apps):**
   ```bash
   kubectl apply -f root-application.yaml
   ```

This will bootstrap the entire GitOps workflow where ArgoCD manages all other applications.
