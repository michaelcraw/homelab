#!/bin/bash

MACHINES=(
  "michael@100.117.229.28|dell-7050"
  "michael@100.96.120.65|sony"
  "michael@100.66.222.35|lenovo"
  "michael@100.64.249.4|hp-nas"
  "michael@100.73.143.19|pi"
  "michael@100.108.102.105|5070"
  "michael@100.106.110.55|dell-7440"
  "chris@100.102.26.15|vt-pc"
)

for ENTRY in "${MACHINES[@]}"; do
  USER_HOST="${ENTRY%|*}"
  NAME="${ENTRY#*|}"
  
  
  echo "[$NAME] Connecting"
  
  
  if ssh -t -o ConnectTimeout=5 -o BatchMode=yes $USER_HOST "sudo apt update && sudo apt upgrade -y" 2>&1; then
    echo "[$NAME]  Update complete"
  else
    echo "[$NAME] offline or unreachable, skipping"
  fi
  echo ""
done

echo "update complete"
