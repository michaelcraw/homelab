# Manifests

Apply everything from the `kubernetes/` directory:

```bash
kubectl apply -f manifests/
```

| File | What it does |
|------|--------------|
| `00-namespace.yaml` | Creates the `homelab` namespace. |
| `homelab-dashboard.yaml` | nginx deployment (3 replicas) + a ConfigMap serving a small landing page. `topologySpreadConstraints` spread the replicas across the Dell 7440 / 5070 / 7050 nodes. |
| `homelab-dashboard-svc.yaml` | NodePort service exposing the dashboard on port `30080` on every node. |

## Try it

Open the dashboard on any node's Tailscale IP:

```
http://100.106.110.55:30080   # Dell 7440 (control plane)
http://100.108.102.105:30080  # Dell 5070
http://100.117.229.28:30080   # Dell 7050
```

See the replicas spread across nodes:

```bash
kubectl -n homelab get pods -o wide
```

## Watch self-healing

Delete a pod and watch the cluster recreate it:

```bash
kubectl -n homelab delete pod -l app=homelab-dashboard --field-selector=...  # or just one pod name
kubectl -n homelab get pods -o wide -w
```

Or drain a whole node (e.g. when shutting one down with the fleet scripts) and
watch the pods reschedule onto the survivors:

```bash
# use the node name from `kubectl get nodes` (defaults to the machine hostname)
kubectl drain dell-5070 --ignore-daemonsets --delete-emptydir-data
kubectl -n homelab get pods -o wide
# bring it back
kubectl uncordon dell-5070
```

## Common ops

```bash
# Scale
kubectl -n homelab scale deploy/homelab-dashboard --replicas=5

# Rollout / restart after an image bump
kubectl -n homelab rollout restart deploy/homelab-dashboard
kubectl -n homelab rollout status deploy/homelab-dashboard

# Logs from all replicas
kubectl -n homelab logs -l app=homelab-dashboard --prefix --tail=20

# Tear down just these workloads
kubectl delete -f .
```
