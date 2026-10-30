#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/download.sh"
LINUX="${LINUX:-6.16.2}"
cd "$SOURCES"
download "https://www.kernel.org/pub/linux/kernel/v6.x/linux-${LINUX}.tar.xz"
D=$(extract "$SOURCES/linux-${LINUX}.tar.xz")
cd "$D"
make mrproper
# minimal config for QEMU boot
make defconfig
# enable virtio, ext4, initramfs-friendly options
./scripts/config --enable CONFIG_VIRTIO --enable CONFIG_VIRTIO_PCI --enable CONFIG_VIRTIO_BLK \
  --enable CONFIG_EXT4_FS --enable CONFIG_DEVTMPFS --enable CONFIG_DEVTMPFS_MOUNT \
  --enable CONFIG_BLK_DEV_INITRD 2>/dev/null || true
make olddefconfig
make -j"$(nproc)"
cp arch/$(uname -m)/boot/bzImage "$MYOS_ROOT/rootfs/vmlinuz" 2>/dev/null || cp arch/$(uname -m)/boot/Image "$MYOS_ROOT/rootfs/vmlinuz" 2>/dev/null || true
echo "Kernel built"
