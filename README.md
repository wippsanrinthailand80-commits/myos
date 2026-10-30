# MyOS — Linux From Scratch (System V init, no systemd)

A from-source Linux distribution built following the **Linux From Scratch 12.4** book,
using **SysVinit** (no systemd) for a clean, minimal system.

## Layout
- `scripts/` — build scripts (chapter5.sh = cross toolchain, ...)
- `sources/` — downloaded tarballs (cached)
- `.github/workflows/build.yml` — GitHub Actions build

## Build (host requirements)
Debian/Ubuntu with: build-essential bison flex texinfo gawk m4 libmpfr-dev libmpc-dev libgmp-dev wget curl git rsync file

## Quick start
```bash
export LFS=/mnt/lfs
bash scripts/chapter5.sh
```

## CI
Pushes to `main` trigger `.github/workflows/build.yml` which builds the cross toolchain
on an ubuntu-latest runner (fast network/disk). Artifacts: `lfs-tools`.

## Init system
System V init (sysvinit) via LFS-Bootscripts. No systemd, no D-Bus dependency in base.
