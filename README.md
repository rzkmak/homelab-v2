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