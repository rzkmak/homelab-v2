# Remote k3s server configuration
K3S_SERVER := rizki@192.168.0.210
K3S_IP := 192.168.0.210
KUBECONFIG_PATH := ~/.kube/k3s-config

.PHONY: help bootstrap install-argocd apply-root status dashboard password grafana quickwit gitea clean setup-kubeconfig setup-passwordless-sudo ssh-server check-connection check-apps wait-for-apps

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Remote k3s server: $(K3S_SERVER)'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bootstrap: install-argocd apply-root ## Complete bootstrap process (install ArgoCD + apply root app)

install-argocd: ## Install ArgoCD in the cluster
	@echo "Creating ArgoCD namespace..."
	kubectl apply -f kubernetes/bootstrap/argocd-namespace.yaml
	@echo "Installing ArgoCD..."
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "Waiting for ArgoCD to be ready..."
	kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
	@echo "ArgoCD installation complete!"

apply-root: ## Apply the root application (app-of-apps)
	@echo "Applying root application..."
	kubectl apply -f kubernetes/bootstrap/root-application.yaml
	@echo "Root application applied. ArgoCD will now sync all applications."

status: ## Show status of all ArgoCD applications
	kubectl get applications -n argocd

password: ## Get the initial ArgoCD admin password
	@echo "ArgoCD admin password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""

dashboard: ## Port-forward to ArgoCD dashboard (https://localhost:8080)
	@echo "Access ArgoCD at https://localhost:8080"
	@echo "Username: admin"
	@echo "Password: run 'make password' to get the password"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

grafana: ## Port-forward to Grafana dashboard (http://localhost:3000)
	@echo "Access Grafana at http://localhost:3000"
	@echo "Username: admin"
	@echo "Password: (your configured password)"
	kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

quickwit: ## Port-forward to Quickwit UI (http://localhost:7280)
	@echo "Access Quickwit at http://localhost:7280"
	@echo "Index: logs"
	kubectl port-forward -n monitoring svc/quickwit-searcher 7280:7280

gitea: ## Port-forward to Gitea (http://localhost:3001)
	@echo "Access Gitea at http://localhost:3001"
	@echo "First time: Complete installation wizard and create admin account"
	kubectl port-forward -n gitea svc/gitea-http 3001:3000

clean: ## Remove ArgoCD and all managed resources
	@echo "Warning: This will delete ArgoCD and all managed applications!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		kubectl delete -f kubernetes/bootstrap/root-application.yaml; \
		kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml; \
		kubectl delete namespace argocd; \
	fi

# Remote cluster management
setup-passwordless-sudo: ## Configure passwordless sudo on remote server
	@echo "Configuring passwordless sudo on $(K3S_SERVER)..."
	@ssh -t $(K3S_SERVER) 'echo "rizki ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/rizki && sudo chmod 0440 /etc/sudoers.d/rizki'
	@echo "Testing passwordless sudo..."
	@ssh $(K3S_SERVER) "sudo whoami" && echo "Success! Passwordless sudo is configured." || echo "Failed. You may need to run this manually."

setup-kubeconfig: ## Fetch kubeconfig from remote k3s server and configure local kubectl
	@echo "Fetching kubeconfig from $(K3S_SERVER)..."
	@echo "Note: This requires passwordless sudo on the remote server"
	@mkdir -p ~/.kube
	@ssh $(K3S_SERVER) "sudo cat /etc/rancher/k3s/k3s.yaml" > $(KUBECONFIG_PATH) || \
		(echo "Error: Failed to fetch kubeconfig. Ensure passwordless sudo is configured." && \
		 echo "Run: ssh $(K3S_SERVER) 'echo \"rizki ALL=(ALL) NOPASSWD: ALL\" | sudo tee /etc/sudoers.d/rizki'" && exit 1)
	@sed -i '' 's/127.0.0.1/$(K3S_IP)/g' $(KUBECONFIG_PATH)
	@echo "Kubeconfig saved to $(KUBECONFIG_PATH)"
	@echo ""
	@echo "To use this config, run:"
	@echo "  export KUBECONFIG=$(KUBECONFIG_PATH)"
	@echo ""
	@echo "Testing connection..."
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes

ssh-server: ## SSH into the k3s server
	ssh $(K3S_SERVER)

check-connection: ## Check connection to the k3s cluster
	@echo "Checking connection to k3s cluster at $(K3S_IP)..."
	@kubectl cluster-info
	@echo ""
	@kubectl get nodes

check-apps: ## Check status of all ArgoCD applications
	@echo "ArgoCD Applications:"
	@kubectl get applications -n argocd
	@echo ""
	@echo "Infrastructure Pods:"
	@kubectl get pods -n kube-system -l app.kubernetes.io/name=sealed-secrets 2>/dev/null || echo "Sealed-secrets not deployed yet"
	@kubectl get pods -n argocd

wait-for-apps: ## Wait for all applications to be healthy
	@echo "Waiting for ArgoCD applications to sync..."
	@echo "This may take several minutes. Press Ctrl+C to stop."
	@echo ""
	@while true; do \
		clear; \
		echo "=== ArgoCD Applications Status ==="; \
		echo ""; \
		kubectl get applications -n argocd 2>/dev/null || echo "No applications found yet"; \
		echo ""; \
		echo "Press Ctrl+C to stop watching..."; \
		sleep 5; \
	done
