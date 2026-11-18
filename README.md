# devpi on Kubernetes

This project builds a [devpi](https://devpi.net) container image and provides a
Helm chart that deploys it to Kubernetes with persistent storage and ingress-based
access.

## Repository layout

```
.
├── Containerfile                  # devpi server image (python:3.12-slim)
├── devpi-entrypoint.sh            # idempotent devpi-init + devpi-server launcher
├── .github/workflows/build.yml    # GHCR build/push workflow
└── chart/devpi/                   # Helm chart
```

## Container image

Build locally:

```sh
docker build -f Containerfile -t devpi .
docker run --rm -p 3141:3141 -v devpi-data:/data devpi
```

The server listens on port `3141` and stores everything in `/data`. `devpi-init`
runs automatically on first start; the data directory is reused on subsequent
starts.

## CI

`.github/workflows/build.yml` builds the image on every push/PR and pushes it to
`ghcr.io/<owner>/<repo>` on `main` and on `v*` tags (tags: branch name, semver,
`latest`, and a sha tag).

## Helm chart

Install:

```sh
helm install devpi ./chart/devpi \
  --set ingress.className=nginx \
  --set ingress.hosts[0].host=devpi.example.com \
  --set persistence.storageClass=longhorn \
  --set persistence.size=10Gi \
  --set devpi.rootPassword=changeme
```

### Key values

| Value | Default | Description |
|---|---|---|
| `ingress.enabled` | `true` | Create an Ingress object |
| `ingress.className` | `nginx` | IngressClass for the Ingress object |
| `ingress.hosts` | `devpi.example.com` | Hosts/paths routed to devpi |
| `ingress.tls` | `[]` | TLS secrets for the Ingress |
| `persistence.enabled` | `true` | Mount a PVC at `/data` |
| `persistence.storageClass` | `""` | StorageClass; empty = cluster default |
| `persistence.size` | `5Gi` | PVC size |
| `devpi.rootPassword` | `""` | Initial `root` password (first start only) |
| `devpi.existingSecret` | `""` | Existing secret with `root-password` key |
| `devpi.extraArgs` | `[]` | Extra `devpi-server` flags |
| `service.type` | `ClusterIP` | Service type |

### Notes

- Keep `replicaCount: 1`: devpi's server directory does not support concurrent
  writers. The default `Recreate` strategy ensures the RWO volume detaches
  cleanly during rollouts.
- The root password only takes effect on the **first** start, when
  `devpi-init` bootstraps `/data`.
- Data survives restarts via the PVC; set `persistence.storageClass` to a
  StorageClass backed by a CSI driver with a Reclaim/Bind policy that suits
  your environment.
