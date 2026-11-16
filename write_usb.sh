#!/usr/bin/env bash
set -euo pipefail

USB_DEV="/dev/disk/by-id/usb-USB_SanDisk_3.2Gen1_04019110be5d736b2116194b15b7059c1936feb887da48466dc5549938bc67d0e9a600000000000000000000e2a15a9aff17081891558107a23145cc-0:0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo \"$0\""
  exit 1
fi

if [[ ! -b "$USB_DEV" ]]; then
  echo "SanDisk USB drive not found at: $USB_DEV"
  exit 1
fi

REAL_DEV="$(readlink -f "$USB_DEV")"
echo "Target USB drive: $REAL_DEV ($USB_DEV)"
lsblk "$REAL_DEV"
echo ""
read -r -p "This will ERASE all data on $REAL_DEV. Type YES to continue: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

echo "Unmounting any mounted partitions on $REAL_DEV..."
for part in "${REAL_DEV}"?*; do
  if [[ -b "$part" ]]; then
    umount "$part" 2>/dev/null || true
  fi
done

echo "Creating GPT partition table and 4 GiB FAT32 boot partition..."
parted -s "$REAL_DEV" mklabel gpt
parted -s "$REAL_DEV" mkpart OPENCORE fat32 1MiB 4097MiB
parted -s "$REAL_DEV" set 1 esp on

partprobe "$REAL_DEV" || true
sleep 2

PART="${USB_DEV}-part1"
if [[ ! -b "$PART" ]]; then
  PART="${REAL_DEV}1"
fi

echo "Formatting $PART as FAT32 (OPENCORE)..."
mkfs.vfat -F 32 -n OPENCORE "$PART"

MNT="$(mktemp -d)"
trap 'umount "$MNT" 2>/dev/null || true; rmdir "$MNT" 2>/dev/null || true' EXIT

mount "$PART" "$MNT"

echo "Copying EFI, com.apple.recovery.boot, and PostInstall to USB..."
cp -r "$SCRIPT_DIR/EFI" "$MNT/"
cp -r "$SCRIPT_DIR/com.apple.recovery.boot" "$MNT/"
cp -r "$SCRIPT_DIR/PostInstall" "$MNT/"

sync
echo "Done! You can now reboot and boot from the SanDisk USB drive (UEFI)."
