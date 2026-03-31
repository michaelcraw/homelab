#!/bin/bash

PRIMARY="/mnt/camera/motion"
SECONDARY="/mnt/camera2/motion"
CONF="/etc/motion/motion.conf"

FREE=$(df -P "$PRIMARY" | awk 'NR==2 {print $5}' | tr -d '%')

if [ "$FREE" -ge 90 ]; then
    sed -i "s|^target_dir .*|target_dir $SECONDARY|" "$CONF"
else
    sed -i "s|^target_dir .*|target_dir $PRIMARY|" "$CONF"
fi

systemctl restart motion
