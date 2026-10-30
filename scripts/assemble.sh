#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"
mkdir -p "$MYOS_ROOT/rootfs"/{bin,sbin,etc,proc,sys,dev,lib,usr/bin,lib64}
"$LFS/tools/bin/${LFS_TGT}-gcc" -static -o "$MYOS_ROOT/rootfs/sbin/init" "$MYOS_ROOT/scripts/init.c"
# provide a shell
cp "$LFS/tools/bin/bash" "$MYOS_ROOT/rootfs/bin/sh" 2>/dev/null || true
# copy dynamic libs needed
cp -a "$LFS"/lib/*.so* "$MYOS_ROOT/rootfs/lib/" 2>/dev/null || true
cp -a "$LFS"/usr/lib/*.so* "$MYOS_ROOT/rootfs/lib/" 2>/dev/null || true
cd "$MYOS_ROOT/rootfs"
find . | cpio -o -H newc 2>/dev/null | gzip > "$MYOS_ROOT/rootfs/initramfs.cpio.gz"
echo "initramfs created"
bash "$MYOS_ROOT/scripts/kernel.sh"
echo "assemble done"
