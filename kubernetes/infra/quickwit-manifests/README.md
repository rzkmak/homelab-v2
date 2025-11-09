# Quickwit Deployment

This directory contains Kubernetes manifests for deploying Quickwit, a cloud-native search engine for logs.

## Overview

Quickwit is deployed as a single-node instance suitable for homelab use. It provides:
- Fast full-text search on logs
- Cost-effective storage with high compression
- Elasticsearch-compatible API
- Web UI for log exploration and querying

## Components

### ConfigMap (`configmap.yaml`)
Contains two configurations:
1. **quickwit.yaml** - Main Quickwit server configuration
2. **index-config.yaml** - Log index schema definition

The index schema defines how logs are stored and indexed:
- `timestamp` - Log timestamp (used for time-range queries)
- `level` - Log level (info, warn, error, etc.)
- `message` - Log message content (full-text searchable)
- `namespace` - Kubernetes namespace
- `pod_name` - Pod name
- `container_name` - Container name
- `node_name` - Node name
- `cluster` - Cluster identifier

### PersistentVolumeClaim (`pvc.yaml`)
Requests 20Gi of storage for log data. Adjust size based on your retention needs.

### Deployment (`deployment.yaml`)
Runs Quickwit with:
- Init container to create the logs index on first run
- Main container running Quickwit server
- Health checks (liveness and readiness probes)
- Resource limits (500m CPU, 1-2Gi memory)

### Service (`service.yaml`)
Exposes Quickwit internally:
- `quickwit-searcher` - For search queries (port 7280)
- `quickwit-indexer` - For ingesting logs (port 7280)

### Ingress (`ingress.yaml`)
Optional external access to Quickwit UI at `quickwit.homelab.local`

## Usage

### Accessing Quickwit UI

**Option 1: Via Ingress (after DNS/hosts configuration)**
```bash
# Add to /etc/hosts
echo "192.168.0.210 quickwit.homelab.local" | sudo tee -a /etc/hosts

# Access UI
open http://quickwit.homelab.local
```

**Option 2: Via Port-forward**
```bash
kubectl port-forward -n monitoring svc/quickwit-searcher 7280:7280
open http://localhost:7280
```

### Querying Logs

**IMPORTANT:** Quickwit uses its own UI and API for querying logs. It does not integrate directly with Grafana's Explore view because Quickwit's Elasticsearch compatibility is limited and doesn't support all Elasticsearch APIs that Grafana requires.

**From Quickwit Web UI (Recommended):**
1. Access Quickwit UI (see access methods below)
2. Select the "logs" index
3. Use Lucene query syntax:
   ```
   namespace:monitoring AND level:error
   pod_name:quickwit* AND message:failed
   container_name:vector AND timestamp:[now-1h TO now]
   ```
4. Use the built-in time range picker

**Via API (for automation/scripts):**
```bash
# Search logs
curl -X POST "http://quickwit-searcher.monitoring.svc.cluster.local:7280/api/v1/logs/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "level:error",
    "max_hits": 10,
    "start_timestamp": 1609459200,
    "end_timestamp": 1609545600
  }'
```

## Log Flow

```
Application → stdout/stderr → Vector (DaemonSet)
                                  ↓
                                  ↓ (transforms + enriches)
                                  ↓
                           Quickwit HTTP API
                                  ↓
                           Quickwit Index
                                  ↓
                           Grafana (queries via ES API)
```

## Monitoring

Check Quickwit status:
```bash
kubectl get pods -n monitoring -l app=quickwit
kubectl logs -n monitoring -l app=quickwit
```

Check index status:
```bash
kubectl exec -n monitoring deploy/quickwit -- quickwit index list
kubectl exec -n monitoring deploy/quickwit -- quickwit index describe --index logs
```

## Troubleshooting

### Logs not appearing
1. Check Vector is running and sending logs:
   ```bash
   kubectl logs -n monitoring daemonset/vector
   ```

2. Check Quickwit is receiving data:
   ```bash
   kubectl logs -n monitoring deploy/quickwit
   ```

3. Verify index exists:
   ```bash
   kubectl exec -n monitoring deploy/quickwit -- quickwit index list
   ```

### Storage full
Increase PVC size in `pvc.yaml` or configure log retention:
```bash
# Edit retention in index configuration
kubectl edit configmap quickwit-config -n monitoring
```

### Performance issues
Increase resource limits in `deployment.yaml`:
```yaml
resources:
  requests:
    cpu: 1000m
    memory: 2Gi
  limits:
    memory: 4Gi
```

## Scaling Considerations

For production use or higher log volumes:
1. Deploy multiple Quickwit nodes (indexers and searchers)
2. Use object storage (S3/MinIO) instead of local disk
3. Configure proper retention policies
4. Set up monitoring and alerting

See Quickwit documentation: https://quickwit.io/docs/
