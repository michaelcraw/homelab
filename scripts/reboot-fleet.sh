#!/bin/bash

MACHINES=(
 "michael@100.117.229.28|dell-7050"
  "michael@100.96.120.65|sony"
  "michael@100.66.222.35|lenovo"
  "michael@100.64.249.4|hp-nas"
  "michael@100.108.102.105|5070")

read -p "reboot pi? (y/n): " PI_ANSWER

if [[ "$PI_ANSWER" == "y" || "$PI_ANSWER" == "Y" ]]; then
  MACHINES+=("michael@100.73.143.19|pi")
  echo "Pi included."
else
  echo "Pi skipped."
fi

echo ""

for ENTRY in "${MACHINES[@]}"; do
  USER_HOST="${ENTRY%|*}"
  NAME="${ENTRY#*|}"

  
  echo "[$NAME] Rebooting..."
 

  if ssh -o ConnectTimeout=5 -o BatchMode=yes $USER_HOST "sudo reboot" 2>&1; then
    echo "[$NAME] reboot sent"
  else
    echo "[$NAME] offline or unreachable, skipping"
  fi
  echo ""
done

echo "reboot is complete"
