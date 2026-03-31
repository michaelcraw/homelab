#!/bin/bash

echo "Which machine do you want to wake?"
echo "1) Sony"
echo "2) Dell-7050"
echo "3) Lenovo"
echo "4) HP-NAS"
echo "5) All"
read -p "Enter choice: " CHOICE

wake_machine() {
  local NAME=$1
  local MAC=$2
  echo "Waking $NAME ($MAC)..."
  wakeonlan $MAC
}

case $CHOICE in
  1) wake_machine "sony" "00:24:be:3a:8d:a1" ;;
  2) wake_machine "dell-7050" "b8:85:84:a0:22:c7" ;;
  3) wake_machine "lenovo" "PENDING" ;;
  4) wake_machine "hp-nas" "PENDING" ;;
  5)
    wake_machine "sony" "00:24:be:3a:8d:a1"
    wake_machine "dell-7050" "b8:85:84:a0:22:c7"
    wake_machine "lenovo" "PENDING"
    wake_machine "hp-nas" "PENDING"
    ;;
  *) echo "Invalid choice" ;;
esac
