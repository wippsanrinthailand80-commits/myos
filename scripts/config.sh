# MyOS build configuration (LFS 12.4, System V init, no systemd)
export MYOS_ROOT="${MYOS_ROOT:-/root/myos}"
export LFS="${LFS:-/mnt/lfs}"
export LFS_TGT="${LFS_TGT:-$(uname -m)-lfs-linux-gnu}"
export MAKEFLAGS="${MAKEFLAGS:--j$(nproc)}"
export SOURCES="${MYOS_ROOT}/sources"
export SCRIPTS="${MYOS_ROOT}/scripts"
export PACKAGES="${MYOS_ROOT}/packages"
export PATH="${LFS}/tools/bin:${PATH}"

# Host requirements check
check_host() {
  for t in bash gcc g++ make ld as awk sed grep find patch tar gzip xz bzip2 m4 perl python3; do
    command -v "$t" >/dev/null 2>&1 || { echo "MISSING: $t"; exit 1; }
  done
  echo "Host OK: $(uname -m)"
}
