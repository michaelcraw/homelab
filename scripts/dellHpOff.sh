#!/bin/bash

echo "Shutting down Dell 7050"
ssh michael@100.117.229.28 "sudo shutdown now" 2>/dev/null
echo "[dell-7050] shutdown sent"

echo "Shutting down HP NAS"
ssh michael@100.64.249.4 "sudo shutdown now" 2>/dev/null
echo "[hp-nas] shutdown sent"

echo "dell-7050 and hpNas shutting down"
