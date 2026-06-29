#!/bin/bash
# Apply the homelab manifests to the k3s cluster from the Mac.
# Requires the kubeconfig created by k8s-install.sh.

KUBECONFIG_FILE=~/.kube/homelab.yaml
MANIFESTS="$(dirname "$0")/../kubernetes/manifests"

if [ ! -f "$KUBECONFIG_FILE" ]; then
  echo "[mac] no kubeconfig at $KUBECONFIG_FILE - run k8s-install.sh first"
  exit 1
fi

export KUBECONFIG="$KUBECONFIG_FILE"

echo "[mac] nodes:"
kubectl get nodes -o wide || { echo "[mac] cluster unreachable"; exit 1; }

echo ""
echo "[mac] applying manifests"
kubectl apply -f "$MANIFESTS"

echo ""
echo "[mac] pods:"
kubectl -n homelab get pods -o wide

echo ""
echo "dashboard on any node: http://100.106.110.55:30080"
