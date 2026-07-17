#!/bin/bash

echo "Shutting down Dell 7050"
ssh michael@100.117.229.28 "sudo shutdown now" 2>/dev/null
echo "[dell-7050] shutdown sent"

echo "Shutting down HP NAS"
ssh michael@100.64.249.4 "sudo shutdown now" 2>/dev/null
echo "[hp-nas] shutdown sent"

echo "Shutting down Dell 5070"
ssh michael@100.108.102.105 "sudo shutdown now" 2>/dev/null
echo "[5070] shutdown sent"

echo "Shutting down pi"
ssh michael@100.73.143.19 "sudo shutdown now" 2>/dev/null
echo "[pi] shutdown sent"

echo "Shutting down 7440"
ssh michael@100.106.110.55 "sudo shutdown now" 2>/dev/null
echo "[7440] shutdown sent"

echo "dell-7050, hpNas,5070, pi. and 7440 shutting down"
