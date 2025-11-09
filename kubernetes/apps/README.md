# Applications

This directory contains ArgoCD Application manifests that define what gets deployed to the cluster.

## Structure

- `infra-apps.yaml` - Points to the infrastructure applications in `kubernetes/infra/`
- Additional application manifests can be added here for user-facing applications

## App-of-Apps Pattern

The root application in `kubernetes/bootstrap/root-application.yaml` watches this directory and automatically deploys any Application manifests found here. This creates a hierarchy:

```
root-application
└── infra-apps
    ├── traefik
    ├── cert-manager
    └── ...
```

Add new applications by creating Application manifests in this directory.
