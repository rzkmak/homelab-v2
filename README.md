# My Homelab

This repository contains the infrastructure and deployment configurations for my homelab.

## Hardware

*   **Server:** Dell OptiPlex 3070 Micro
*   **CPU:** Intel Core i5-8500T
*   **Memory:** 32GB RAM

## Core Components

*   **Kubernetes:** k3s
*   **GitOps:** ArgoCD
*   **Ingress:** Traefik
*   **Secure Tunneling:** (To be determined: Cloudflare Tunnel, Tailscale, etc.)
*   **Observability:**
    *   **Logs:** Loki, Promtail
    *   **Metrics:** Prometheus, OpenTelemetry
    *   **Visualization:** Grafana
*   **Artifact Hosting:** Gitea

## Goals

*   Learn infrastructure management best practices.
*   Gain experience with Kubernetes, GitOps, and observability.
*   Host and manage personal applications.

---

### **Homelab Setup: k3s and ArgoCD Installation Guide**

This guide outlines the steps taken to set up a k3s Kubernetes cluster on a Dell OptiPlex 3070 Micro and install ArgoCD for GitOps management.

#### **Prerequisites:**

*   A Dell OptiPlex 3070 Micro (or similar Linux-based server) with SSH access.
*   A local machine (macOS in this case) with `kubectl` installed.
*   A Git repository for your homelab configurations.

#### **Phase 1: k3s Cluster Installation (on Dell OptiPlex Server)**

1.  **SSH into your Dell OptiPlex server.**
    ```bash
    ssh user@your_server_ip
    ```
    *(Replace `user` with your username and `your_server_ip` with the IP address of your Dell OptiPlex)*

2.  **Install k3s (stable version recommended):**
    It was determined that using a stable k3s version is best for compatibility. We chose `v1.28.5+k3s1`.
    ```bash
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.5+k3s1" sh -
    ```

3.  **Verify k3s installation on the server:**
    ```bash
    sudo k3s kubectl get nodes
    ```
    You should see a single node with `Ready` status.

#### **Phase 2: Local `kubectl` Configuration (on Local Machine)**

1.  **Copy `kubeconfig` from server to local machine:**
    The `k3s.yaml` file contains your cluster's access credentials. It's owned by root, so first copy it to your user's home directory on the server and adjust permissions.

    *   **On the server:**
        ```bash
        sudo cp /etc/rancher/k3s/k3s.yaml $HOME/k3s.yaml
        sudo chown $(whoami):$(whoami) $HOME/k3s.yaml
        ```
    *   **On your local machine:**
        ```bash
        scp user@your_server_ip:~/k3s.yaml ~/.kube/config
        ```
        *(Replace `user` and `your_server_ip`)*
    *   **(Optional) Clean up on the server:**
        ```bash
        rm ~/k3s.yaml
        ```

2.  **Update `kubeconfig` server IP:**
    The copied `kubeconfig` will likely point to `127.0.0.1`. You *must* change this to your server's actual IP address.

    *   **On your local machine, open `~/.kube/config` in a text editor:**
        ```bash
        nano ~/.kube/config
        ```
    *   **Find the line:** `server: https://127.0.0.1:6443`
    *   **Replace `127.0.0.1` with your server's IP address** (e.g., `192.168.1.100`):
        ```
        server: https://192.168.1.100:6443
        ```
    *   **Save and exit** the text editor.

3.  **Install compatible `kubectl` on local machine (macOS):**
    Ensure your local `kubectl` version matches the k3s version (e.g., `v1.28.5`).

    ```bash
    export KUBECTL_VERSION="v1.28.5" # Match your k3s version
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/darwin/arm64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    ```

4.  **Verify local `kubectl` connectivity:**
    ```bash
    kubectl get nodes
    ```
    This should now successfully connect to your k3s cluster and show your node.

#### **Phase 3: ArgoCD Installation (on k3s Cluster)**



1.  **Delete any previous partial ArgoCD installations:**

    If you attempted previous installations, clean them up first.

    ```bash

    kubectl delete -f /Users/user/github.com/rzkmak/homelab-v2/kubernetes/bootstrap/argocd-complete.yaml # If it exists

    kubectl delete -f /Users/user/github.com/rzkmak/homelab-v2/kubernetes/bootstrap/argocd.yaml # If it exists

    ```



2.  **Apply the official ArgoCD installation manifest:**

    This is the most reliable way to install ArgoCD.

    ```bash

    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    ```



3.  **Verify ArgoCD pod status:**

    Watch for all ArgoCD pods to reach the `Running` state.

    ```bash

    kubectl get pods -n argocd -w

    ```

    (Press `Ctrl+C` when done watching)



4.  **Access the ArgoCD UI:**

    *   **Port-forward the ArgoCD server to your local machine:**

        ```bash

        kubectl port-forward svc/argocd-server -n argocd 8080:80

        ```

    *   **Open your web browser** to `http://localhost:8080`.



5.  **Log in to ArgoCD:**

    *   **Username:** `admin`

    *   **Get initial password:**

        ```bash

        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

        ```

    *   Copy the output and paste it into the password field.



#### **Phase 4: Connecting ArgoCD to a Private Git Repository**



To allow ArgoCD to securely access a private Git repository, we will use an SSH key pair.



1.  **Create an SSH Key Pair:**

    On your local machine, create a new SSH key pair dedicated to ArgoCD.



    ```bash

    ssh-keygen -t ed25519 -C "argocd@homelab" -f ./argocd-ssh-key

    ```

    *(Do not set a passphrase for this key)*



2.  **Add the Public Key as a Deploy Key in GitHub:**

    *   Copy the public key to your clipboard:

        ```bash

        cat argocd-ssh-key.pub

        ```

    *   Navigate to your GitHub repository's settings: `https://github.com/rzkmak/homelab-v2/settings/keys`

    *   Click **"Add deploy key"**.

    *   Give it a title (e.g., "ArgoCD").

    *   Paste the public key into the "Key" field.

    *   **Do not** check "Allow write access".

    *   Click **"Add key"**.



3.  **Add the Private Key to ArgoCD as a Secret:**

    Create a Kubernetes secret in the `argocd` namespace containing the private key.



    ```bash

    kubectl create secret generic argocd-repo-secret -n argocd --from-file=sshPrivateKey=./argocd-ssh-key

    ```



4.  **Update the ArgoCD Application to Use SSH:**

    The `app-of-apps.yaml` manifest needs to be updated to use the SSH URL of your repository.



    *   **File:** `kubernetes/bootstrap/app-of-apps.yaml`

    *   **Change `repoURL` to:** `git@github.com:rzkmak/homelab-v2.git`



5.  **Apply the Updated Application Manifest:**

    ```bash

    kubectl apply -f /Users/user/github.com/rzkmak/homelab-v2/kubernetes/bootstrap/app-of-apps.yaml

    ```



6.  **Clean Up Local SSH Key Files:**

    Once the private key is securely stored in the cluster, remove the key files from your local machine.

    ```bash

    rm argocd-ssh-key argocd-ssh-key.pub

    ```