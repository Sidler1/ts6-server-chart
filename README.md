# TeamSpeak 6 Server Helm Chart

[![Version](https://img.shields.io/github/tag/Sidler1/ts6-server-chart.svg)](https://github.com/sidler2/ts6-server-chart/tags)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/sidler2/ts6-server-chart/blob/main/LICENSE)
[![Release](https://img.shields.io/helm/artifacthub/v/sidler1/teamspeak.svg)](https://artifacthub.io/packages/helm/sidler2/teamspeak)

A Kubernetes Helm chart for deploying TeamSpeak 6 Server with optional MariaDB persistence, ingress support,
autoscaling, and network policies.

## Introduction

This Helm chart deploys a stateful TeamSpeak 6 Server instance on Kubernetes. It includes:

- **StatefulSet** for reliable pod management and persistent storage.
- **Service** exposing voice (UDP), file transfer (TCP), and query (TCP) ports.
- **ConfigMap/Secret** for server configuration (`tsserver.yaml`).
- **Optional MariaDB** StatefulSet for external database (SQLite by default).
- **Ingress** for secure query access (HTTP/TCP passthrough).
- **Horizontal Pod Autoscaler (HPA)** for scaling based on CPU.
- **NetworkPolicy** for traffic control.
- **Init Container** for setup (directory creation, config copy).
- **NOTES.txt** with post-install instructions.

Designed for production-like setups, with configurable persistence via PVC.

## Features

- **Persistent Storage**: Mounts `/var/tsserver` for database, logs, and config.
- **Database Options**: SQLite (default) or MariaDB (optional).
- **Security**: Runs as non-root (UID 1000), fsGroup for volume ownership, secrets for credentials.
- **Scalability**: HPA support; single-replica by default (StatefulSet-ready).
- **Observability**: Configurable resources, probes, and logs.
- **Customization**: Full `tsserver.yaml` templating via helpers.
- **Helm Best Practices**: Labels, selectors, hooks for tests.

## Prerequisites

- Kubernetes 1.21+ cluster.
- Helm 3.8+.
- Persistent Volume support (e.g., local, NFS, or cloud storage like EBS/GPD).
- Ingress controller (e.g., nginx) for ingress-enabled deployments.
- NetworkPolicy support if enabling policies.

## Installation

Add the repo (if hosted) and install:

```bash
# Add repository (replace with actual repo URL if published)
helm repo add sidler2 https://sidler2.github.io/teamspeak-helm-chart
helm repo update

# Install the chart
helm install my-teamspeak . -n teamspeak --create-namespace -f values.yaml

# Or with custom values
helm install my-teamspeak . -n teamspeak --create-namespace --set mariadb.enabled=true,mariadb.auth.rootPassword=securepass
```

Verify deployment:

```bash
kubectl get sts -n teamspeak
kubectl get svc -n teamspeak
kubectl get pvc -n teamspeak  # If persistence enabled
```

Post-install notes will display automatically (or view with `helm get notes my-teamspeak -n teamspeak`).

## Configuration

Key values in `values.yaml`:

| Parameter               | Description                                    | Default                              |
|-------------------------|------------------------------------------------|--------------------------------------|
| `replicaCount`          | Number of replicas                             | `1`                                  |
| `image.repository`      | TeamSpeak image repo                           | `teamspeaksystems/teamspeak6-server` |
| `image.tag`             | Image tag (falls back to `appVersion`)         | `""`                                 |
| `service.type`          | Service type (ClusterIP/NodePort/LoadBalancer) | `LoadBalancer`                       |
| `voice.port`            | Voice UDP port                                 | `9987`                               |
| `filetransfer.port`     | File transfer TCP port                         | `30033`                              |
| `webquery.port`         | Query HTTP port                                | `10080`                              |
| `persistence.enabled`   | Enable PVC for data                            | `true`                               |
| `persistence.size`      | PVC size                                       | `8Gi`                                |
| `mariadb.enabled`       | Enable MariaDB backend                         | `false`                              |
| `mariadb.auth.database` | MariaDB DB name                                | `teamspeak`                          |
| `mariadb.auth.username` | MariaDB user                                   | `ts`                                 |
| `mariadb.auth.password` | MariaDB password (set securely!)               | `tspass`                             |
| `autoscaling.enabled`   | Enable HPA                                     | `false`                              |
| `networkPolicy.enabled` | Enable NetworkPolicies                         | `false`                              |
| `ingress.enabled`       | Enable Ingress for query                       | `false`                              |
| `licenseAccepted`       | Accept EULA in config                          | `true`                               |
| `customer`              | Custom label                                   | `"sidler2"`                          |

For full config, see [values.yaml](teamspeak/values.yaml).

Override via `--set` or custom YAML:

```yaml
# Custom values example
mariadb:
  enabled: true
  auth:
    rootPassword: "supersecret"
    password: "supersecret"
persistence:
  size: 10Gi
```

Upgrade:

```bash
helm upgrade my-teamspeak . -n teamspeak -f custom-values.yaml
```

## Usage

### Accessing the Server

- **Voice Connection**: Use TeamSpeak 6 client to connect to the service IP:9987 (UDP).
- **Query/Admin**: Telnet to service IP:10080 (`telnet <IP> 10080`, then `login serveradmin <pass>`).
- **Port Forward for Testing**:
  ```bash
  kubectl port-forward svc/my-teamspeak 9987:9987/udp -n teamspeak
  # Connect to localhost:9987
  ```
- **Logs**: `kubectl logs sts/my-teamspeak -n teamspeak -f`

### Database

- **SQLite**: File-based at `/var/tsserver/sql/teamspeak`.
- **MariaDB**: Separate StatefulSet; connect via `mariadb -h my-teamspeak-mariadb -u ts -p`.

### Scaling

Enable HPA in values and apply:

```bash
kubectl apply -f templates/hpa.yaml  # Or via helm upgrade
```

## Testing

Run Helm tests:

```bash
helm test my-teamspeak -n teamspeak
```

Tests include:

- Network connectivity (TCP/UDP ports, optional MariaDB).
- Database access (if MariaDB enabled).
- ConfigMap/Secret validation.

## Uninstall

```bash
helm uninstall my-teamspeak -n teamspeak
kubectl delete namespace teamspeak  # If created via chart
```

**Warning**: This deletes PVCs and data unless `--keep-history` is used.

## Contributing

1. Fork the repo.
2. Create a feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit changes (`git commit -m 'Add some AmazingFeature'`).
4. Push (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

Lint and test:

```bash
helm lint .
helm template . --debug
```

## License

Apache 2.0 - see [LICENSE](LICENSE).

## Credits

- Based on TeamSpeak 6 Server docs.
- Helm chart structure inspired by Bitnami patterns (customized, no dependencies).

For issues or support: [@Sidler12 on X](https://x.com/Sidler12) [Mail](mailto:sidler2@sidler2.com).