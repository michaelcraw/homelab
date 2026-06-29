#!/bin/bash
# Stand up the k3s cluster from the Mac: server on 7440, agents on 5070 + 7050.
# Networked over Tailscale (flannel on tailscale0). Safe to re-run.

SERVER="michael@100.106.110.55"   # Dell 7440 - control plane
SERVER_IP="100.106.110.55"

AGENTS=(
  "michael@100.108.102.105|dell-5070|100.108.102.105"
  "michael@100.117.229.28|dell-7050|100.117.229.28"
)

# --- 1. Control plane (Dell 7440) ---
echo "[dell-7440] installing k3s server"
ssh -o ConnectTimeout=5 "$SERVER" "curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip $SERVER_IP \
  --node-external-ip $SERVER_IP \
  --flannel-iface tailscale0 \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --node-label fleet=dell-7440" 2>&1 \
  && echo "[dell-7440] server up" || { echo "[dell-7440] FAILED - aborting"; exit 1; }

# --- 2. Join token ---
echo "[dell-7440] fetching node-token"
TOKEN=$(ssh "$SERVER" "sudo cat /var/lib/rancher/k3s/server/node-token")
if [ -z "$TOKEN" ]; then
  echo "[dell-7440] could not read node-token - aborting"
  exit 1
fi

# --- 3. Workers ---
for ENTRY in "${AGENTS[@]}"; do
  USER_HOST="${ENTRY%%|*}"
  REST="${ENTRY#*|}"
  NAME="${REST%%|*}"
  NODE_IP="${REST#*|}"

  echo "[$NAME] joining as agent"
  if ssh -o ConnectTimeout=5 "$USER_HOST" "curl -sfL https://get.k3s.io | \
      K3S_URL=https://$SERVER_IP:6443 K3S_TOKEN='$TOKEN' sh -s - agent \
      --node-ip $NODE_IP \
      --flannel-iface tailscale0 \
      --node-label fleet=$NAME" 2>&1; then
    echo "[$NAME] joined"
  else
    echo "[$NAME] offline or unreachable, skipping"
  fi
  echo ""
done

# --- 4. Kubeconfig on the Mac ---
echo "[mac] copying kubeconfig"
mkdir -p ~/.kube
if scp "$SERVER:/etc/rancher/k3s/k3s.yaml" ~/.kube/homelab.yaml 2>/dev/null; then
  sed -i '' "s/127.0.0.1/$SERVER_IP/" ~/.kube/homelab.yaml
  echo "[mac] kubeconfig at ~/.kube/homelab.yaml"
  echo "[mac] run: export KUBECONFIG=~/.kube/homelab.yaml && kubectl get nodes"
else
  echo "[mac] kubeconfig copy failed"
fi

echo ""
echo "cluster install complete"
