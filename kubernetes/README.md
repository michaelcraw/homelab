# Kubernetes (k3s) — Cluster

Lightweight Kubernetes (k3s) running across fleet machines, networked over the
Tailscale mesh so the cluster works regardless of which physical LAN each node
sits on.

## Current nodes

The cluster is built on the three always-/currently-available machines. The
**control plane lives on the Dell 7440** — it's the always-on kiosk with an
NVMe disk, so the k3s datastore stays fast and the API endpoint stays up even
when the desktop machines reboot.

| Node | Tailscale IP | k3s role | Why |
|------|-------------|----------|-----|
| Dell 7440 | 100.106.110.55 | server (control plane + worker) | Always-on, NVMe datastore, modern i5-1345U |
| Dell 5070 | 100.108.102.105 | agent (worker) | i7-9700T, 32GB, 1TB NVMe — heavy workloads |
| Dell 7050 | 100.117.229.28 | agent (worker) | i7-6700, 32GB — heavy workloads |

> **Expanding later:** HP Compaq (`100.64.249.4`) and Lenovo (`100.66.222.35`)
> can join as additional workers when they come online — just run the agent
> install (step 2) on them with their own `--node-ip` and `fleet=` label.

The cluster runs Flannel over the `tailscale0` interface, so pod and node
traffic rides the WireGuard tunnel. This keeps things working even when nodes
are on different networks.

## Quick start (scripted)

From the Mac, the whole bring-up is two scripts:

```bash
./scripts/k8s-install.sh   # installs server on 7440, joins 5070 + 7050, copies kubeconfig
./scripts/k8s-deploy.sh    # applies kubernetes/manifests/ to the cluster
```

The manual steps below are what those scripts run, for reference / one-off use.

## 1. Install the control plane (Dell 7440)

Run on **Dell 7440**. Binding to the Tailscale IP makes the API server and
flannel use the tunnel instead of whatever happens to be `eth0`.

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip 100.106.110.55 \
  --node-external-ip 100.106.110.55 \
  --flannel-iface tailscale0 \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --node-label fleet=dell-7440
```

Notes:
- `--disable traefik` — keep the cluster minimal; expose services with NodePort
  (see manifests) and front them with the existing Nginx/Tailscale Funnel on
  Dell 7050 if you want WAN access.
- The control plane is also schedulable here, so it runs workloads too.
- The 7440 also drives the Grafana kiosk display — k3s is lightweight and won't
  interfere, but keep an eye on the 16GB RAM if you schedule heavy pods here.

Grab the join token for the agents:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

## 2. Join the worker nodes

Run on **Dell 5070** (`fleet=dell-5070`) and **Dell 7050** (`fleet=dell-7050`),
substituting the token from step 1.

Dell 5070:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://100.106.110.55:6443 \
  K3S_TOKEN='<node-token>' sh -s - agent \
  --node-ip 100.108.102.105 \
  --flannel-iface tailscale0 \
  --node-label fleet=dell-5070
```

Dell 7050:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://100.106.110.55:6443 \
  K3S_TOKEN='<node-token>' sh -s - agent \
  --node-ip 100.117.229.28 \
  --flannel-iface tailscale0 \
  --node-label fleet=dell-7050
```

## 3. Verify the cluster

On Dell 7440:

```bash
sudo k3s kubectl get nodes -o wide
```

You should see all three nodes `Ready`.

## 4. Control the cluster from the Mac

Copy the kubeconfig from the control plane and point it at the Tailscale IP:

```bash
# On the Mac
mkdir -p ~/.kube
scp michael@100.106.110.55:/etc/rancher/k3s/k3s.yaml ~/.kube/homelab.yaml
sed -i '' 's/127.0.0.1/100.106.110.55/' ~/.kube/homelab.yaml
export KUBECONFIG=~/.kube/homelab.yaml

kubectl get nodes
```

(`brew install kubectl` if you don't have it.)

## 5. Deploy the workloads

```bash
kubectl apply -f manifests/
```

This creates the `homelab` namespace and the demo landing-page deployment that
spreads three replicas across the nodes and self-heals — see
[manifests/README.md](manifests/README.md).

## Layout

```
kubernetes/
├── README.md                     # this file — cluster install/join
└── manifests/
    ├── README.md                 # what each manifest does + ops cheatsheet
    ├── 00-namespace.yaml         # homelab namespace
    ├── homelab-dashboard.yaml    # demo deploy: 3 replicas, spread across nodes
    └── homelab-dashboard-svc.yaml# NodePort service (port 30080)
```

## Teardown

```bash
# Agents (5070, 7050)
/usr/local/bin/k3s-agent-uninstall.sh

# Server (7440)
/usr/local/bin/k3s-uninstall.sh
```
