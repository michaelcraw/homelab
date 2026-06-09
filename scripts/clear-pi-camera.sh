#!/bin/bash

PI_IP="100.73.143.19"
PI_USER="michael"

CAMERA1_USAGE=$(ssh $PI_USER@$PI_IP "du -sh /mnt/camera/motion 2>/dev/null || echo '0B'")
CAMERA2_USAGE=$(ssh $PI_USER@$PI_IP "du -sh /mnt/camera2/motion 2>/dev/null || echo '0B'")
CAMERA1_FREE=$(ssh $PI_USER@$PI_IP "df -h /mnt/camera | tail -1 | awk '{print \$4}'")
CAMERA2_FREE=$(ssh $PI_USER@$PI_IP "df -h /mnt/camera2 | tail -1 | awk '{print \$4}'")

echo "  Drive 1 (/mnt/camera):"
echo "    Used by footage: $CAMERA1_USAGE"
echo "    Free space:      $CAMERA1_FREE"
echo ""
echo "  Drive 2 (/mnt/camera2):"
echo "    Used by footage: $CAMERA2_USAGE"
echo "    Free space:      $CAMERA2_FREE"
echo ""

# Ask which drives to clear
echo "Which drives do you want to clear?"
echo "  1) Drive 1 only (/mnt/camera)"
echo "  2) Drive 2 only (/mnt/camera2)"
echo "  3) Both drives"
echo "  4) Cancel"
echo ""
read -p "Enter choice [1-4]: " CHOICE

case $CHOICE in
    1)
        echo ""
        read -p "Are you sure you want to delete all footage on Drive 1? (y/n): " CONFIRM
        if [ "$CONFIRM" = "y" ]; then
            echo "Clearing Drive 1"
            ssh $PI_USER@$PI_IP "sudo rm -rf /mnt/camera/motion/* 2>/dev/null; echo 'Drive 1 cleared.'"
        else
            echo "Cancelled."
        fi
        ;;
    2)
        echo ""
        read -p "Are you sure you want to delete all footage on Drive 2? (y/n): " CONFIRM
        if [ "$CONFIRM" = "y" ]; then
            echo "Clearing Drive 2"
            ssh $PI_USER@$PI_IP "sudo rm -rf /mnt/camera2/motion/* 2>/dev/null; echo 'Drive 2 cleared.'"
        else
            echo "Cancelled."
        fi
        ;;
    3)
        echo ""
        read -p "Are you sure you want to delete ALL footage on BOTH drives? (y/n): " CONFIRM
        if [ "$CONFIRM" = "y" ]; then
            echo "Clearing both drives"
            ssh $PI_USER@$PI_IP "sudo rm -rf /mnt/camera/motion/* /mnt/camera2/motion/* 2>/dev/null; echo 'Both drives cleared.'"
        else
            echo "Cancelled."
        fi
        ;;
    4)
        echo "Cancelled."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Done. Updated drive usage:"
echo ""
ssh $PI_USER@$PI_IP "df -h /mnt/camera /mnt/camera2 | tail -2"
echo ""
