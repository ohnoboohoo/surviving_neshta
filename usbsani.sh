#!/bin/bash

# USB Sanitizer Script (Ubuntu/Linux)
# Requires: clamav, lsblk, sudo privileges

set -e

echo "🔍 Detecting USB drives..."

# List removable drives
lsblk -o NAME,MODEL,SIZE,TRAN,HOTPLUG,MOUNTPOINT | grep -i "1"

echo
read -rp "Enter your USB device (e.g., sdb): " usbdev
usbpath="/dev/$usbdev"
partition="${usbpath}1"

echo "🚨 WARNING: This will scan and optionally wipe $partition"
read -rp "Continue? (y/n): " confirm
[[ $confirm != "y" ]] && exit 1

echo "📦 Creating mount point..."
sudo mkdir -p /mnt/usbscan
echo "🔒 Mounting USB in read-only mode..."
sudo mount -o ro "$partition" /mnt/usbscan

echo "🧪 Scanning with ClamAV..."
sudo clamscan -r /mnt/usbscan > scan_report.txt

infected=$(grep "Infected files:" scan_report.txt | awk '{print $3}')

if [[ "$infected" -eq 0 ]]; then
    echo "✅ No threats found."
    sudo umount /mnt/usbscan
else
    echo "⚠️ Detected $infected infected file(s):"
    grep FOUND scan_report.txt

    echo
    read -rp "Do you want to WIPE the USB drive? This will ERASE all data (y/n): " wipeconfirm
    if [[ $wipeconfirm == "y" ]]; then
        echo "💣 Wiping $usbpath..."
        sudo umount /mnt/usbscan || true
        sudo dd if=/dev/zero of="$usbpath" bs=1M status=progress
        echo "🧹 Creating new FAT32 filesystem..."
        sudo mkfs.vfat "$usbpath"
        echo "✅ Drive sanitized and reformatted."
    else
        echo "❌ Skipped wiping. Unmounting..."
        sudo umount /mnt/usbscan
    fi
fi

echo "📝 Scan report saved to: scan_report.txt"
