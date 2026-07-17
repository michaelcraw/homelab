#!/bin/bash

echo "waking Dell 7050"
ssh michael@100.96.120.65 "wakeonlan -i 192.168.8.255 b8:85:84:a0:22:c7"
echo "[dell-7050] wake packet sent"

echo "waking HP NAS"
ssh michael@100.96.120.65 "wakeonlan -i 192.168.8.255 6c:3b:e5:3a:e2:81"
echo "[hp-nas] wake packet sent"

echo "waking Dell 5070"
ssh michael@100.96.120.65 "wakeonlan -i 192.168.8.255 00:4e:01:bc:04:ba"
echo "[5070] wake packet sent"
