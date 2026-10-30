#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/download.sh"
check_host

mkdir -p "$LFS"/{etc,var,usr/{bin,lib,sbin}} "$LFS/tools" "$LFS/sources"
ln -sfn usr/bin "$LFS/bin"; ln -sfn usr/lib "$LFS/lib"; ln -sfn usr/sbin "$LFS/sbin" 2>/dev/null || true
export PATH="$LFS/tools/bin:$PATH"

cd "$SOURCES"

# versions
BINUTILS=2.45; GCC=15.2.0; LINUX=6.16.2; GLIBC=2.42
M4=1.4.20; NCURSES=6.5; BASH=5.3; COREUTILS=9.7; DIFFUTILS=3.12
FILE=5.46; FINDUTILS=4.10.0; GAWK=5.3.2; GREP=3.12; GZIP=1.14
MAKE=4.4.1; PATCH=2.8; SED=4.9; TAR=1.35; XZ=5.8.1

step() { echo "===== $* ====="; }

# --- 5.2 binutils pass 1 ---
step "binutils pass1"
download "https://sourceware.org/pub/binutils/releases/binutils-${BINUTILS}.tar.xz"
D=$(extract "$SOURCES/binutils-${BINUTILS}.tar.xz")
cd "$D"
mkdir -v build && cd build
../configure --prefix="$LFS/tools" --with-sysroot="$LFS" --target="$LFS_TGT" --disable-nls --enable-gprofng=no --disable-werror --enable-new-dtags --enable-default-hash-style=gnu
make
make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.3 gcc pass 1 ---
step "gcc pass1"
download "https://ftpmirror.gnu.org/gnu/gcc/gcc-${GCC}/gcc-${GCC}.tar.xz"
# prereqs
for p in gmp-6.3.0 mpfr-4.2.2 mpc-1.3.1; do :; done
download "https://ftpmirror.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz"
download "https://ftpmirror.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz"
download "https://ftpmirror.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz"
D=$(extract "$SOURCES/gcc-${GCC}.tar.xz")
cd "$D"
tar -xf "$SOURCES/gmp-6.3.0.tar.xz"; mv gmp-6.3.0 gmp
tar -xf "$SOURCES/mpfr-4.2.2.tar.xz"; mv mpfr-4.2.2 mpfr
tar -xf "$SOURCES/mpc-1.3.1.tar.gz"; mv mpc-1.3.1 mpc
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 2>/dev/null || true
mkdir -v build && cd build
../configure --target="$LFS_TGT" --prefix="$LFS/tools" --with-glibc-version=2.42 --with-sysroot="$LFS" --with-newlib --without-headers --enable-default-pie --enable-default-ssp --disable-nls --disable-shared --disable-multilib --disable-threads --disable-libatomic --disable-libgomp --disable-libquadmath --disable-libssp --disable-libvtv --disable-libstdcxx --enable-languages=c,c++
make
make install
cd "$LFS/tools/bin"; ln -sf "$LFS_TGT-gcc" "$LFS_TGT-cc"
cd "$SOURCES"; rm -rf "$D"

# --- 5.4 linux headers ---
step "linux headers"
download "https://www.kernel.org/pub/linux/kernel/v6.x/linux-${LINUX}.tar.xz"
D=$(extract "$SOURCES/linux-${LINUX}.tar.xz")
cd "$D"
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include "$LFS/usr"
cd "$SOURCES"; rm -rf "$D"

# --- 5.5 glibc ---
step "glibc"
download "https://ftpmirror.gnu.org/gnu/glibc/glibc-${GLIBC}.tar.xz"
D=$(extract "$SOURCES/glibc-${GLIBC}.tar.xz")
cd "$D"
mkdir -v build && cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr --host="$LFS_TGT" --build="$(../scripts/config.guess)" --enable-kernel=5.4 --with-headers="$LFS/usr/include" --disable-nscd libc_cv_slibdir=/usr/lib
make
make DESTDIR="$LFS" install
sed '/RTLDLIST=/s@/usr@@g' -i "$LFS/usr/bin/ldd"
cd "$SOURCES"; rm -rf "$D"

# --- 5.6 libstdc++ ---
step "libstdc++"
download "https://ftpmirror.gnu.org/gnu/gcc/gcc-${GCC}/gcc-${GCC}.tar.xz"
D=$(extract "$SOURCES/gcc-${GCC}.tar.xz")
cd "$D"
mkdir -v build && cd build
../libstdc++-v3/configure --host="$LFS_TGT" --build="$(../config.guess)" --prefix=/usr --disable-multilib --disable-nls --disable-libstdcxx-pch --with-gxx-include-dir="/tools/$LFS_TGT/include/c++/${GCC}"
make
make DESTDIR="$LFS" install
rm -v "$LFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la" 2>/dev/null || true
cd "$SOURCES"; rm -rf "$D"

echo "Chapter 5 cross-toolchain DONE"

# --- 5.7 m4 ---
step "m4"
download "https://ftpmirror.gnu.org/gnu/m4/m4-1.4.20.tar.xz"
D=$(extract "$SOURCES/m4-1.4.20.tar.xz")
cd "$D"
./configure --prefix="$LFS/tools" --build="$(build-aux/config.guess)" --host="$LFS_TGT"
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.8 ncurses ---
step "ncurses"
download "https://invisible-mirror.net/archives/ncurses/ncurses-6.5.tar.gz"
D=$(extract "$SOURCES/ncurses-6.5.tar.gz")
cd "$D"
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i configure 2>/dev/null || true
./configure --prefix="$LFS/tools" --with-shared --without-debug --without-ada --enable-widec --enable-overwrite --host="$LFS_TGT" --build="$(./config.guess)"
make; make install
ln -sf libncursesw.so "$LFS/tools/lib/libncurses.so"
cd "$SOURCES"; rm -rf "$D"

# --- 5.9 bash ---
step "bash"
download "https://ftpmirror.gnu.org/gnu/bash/bash-5.3.tar.gz"
D=$(extract "$SOURCES/bash-5.3.tar.gz")
cd "$D"
./configure --prefix="$LFS/tools" --without-bash-malloc --host="$LFS_TGT" --build="$(support/config.guess)"
make; make install
ln -sf bash "$LFS/tools/bin/sh"
cd "$SOURCES"; rm -rf "$D"

# --- 5.10 coreutils ---
step "coreutils"
download "https://ftpmirror.gnu.org/gnu/coreutils/coreutils-9.7.tar.xz"
D=$(extract "$SOURCES/coreutils-9.7.tar.xz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)" --enable-install-program=hostname --disable-nls
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.11 diffutils ---
step "diffutils"
download "https://ftpmirror.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz"
D=$(extract "$SOURCES/diffutils-3.12.tar.xz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.12 file ---
step "file"
download "https://astron.com/pub/file/file-5.46.tar.gz"
D=$(extract "$SOURCES/file-5.46.tar.gz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(./config.guess)"
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.13 findutils ---
step "findutils"
download "https://ftpmirror.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz"
D=$(extract "$SOURCES/findutils-4.10.0.tar.xz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)" --disable-nls
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.14 gawk ---
step "gawk"
download "https://ftpmirror.gnu.org/gnu/gawk/gawk-5.3.2.tar.xz"
D=$(extract "$SOURCES/gawk-5.3.2.tar.xz")
cd "$D"
sed -i 's/extras//' Makefile.in
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.15 grep ---
step "grep"
download "https://ftpmirror.gnu.org/gnu/grep/grep-3.12.tar.xz"
D=$(extract "$SOURCES/grep-3.12.tar.xz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)" --disable-nls
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.16 gzip ---
step "gzip"
download "https://ftpmirror.gnu.org/gnu/gzip/gzip-1.14.tar.xz"
D=$(extract "$SOURCES/gzip-1.14.tar.xz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.17 make ---
step "make"
download "https://ftpmirror.gnu.org/gnu/make/make-4.4.1.tar.gz"
D=$(extract "$SOURCES/make-4.4.1.tar.gz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)" --without-guile
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.18 patch ---
step "patch"
download "https://ftpmirror.gnu.org/gnu/patch/patch-2.8.tar.xz"
D=$(extract "$SOURCES/patch-2.8.tar.xz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.19 sed ---
step "sed"
download "https://ftpmirror.gnu.org/gnu/sed/sed-4.9.tar.xz"
D=$(extract "$SOURCES/sed-4.9.tar.xz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)" --disable-nls
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.20 tar ---
step "tar"
download "https://ftpmirror.gnu.org/gnu/tar/tar-1.35.tar.xz"
D=$(extract "$SOURCES/tar-1.35.tar.xz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)" --disable-nls
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.21 xz ---
step "xz"
download "https://github.com/tukaani-project/xz/releases/download/v5.8.1/xz-5.8.1.tar.xz"
D=$(extract "$SOURCES/xz-5.8.1.tar.xz")
cd "$D"
./configure --prefix="$LFS/tools" --host="$LFS_TGT" --build="$(build-aux/config.guess)" --disable-static
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.22 binutils pass 2 ---
step "binutils pass2"
download "https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz"
D=$(extract "$SOURCES/binutils-2.45.tar.xz")
cd "$D"
mkdir -v build && cd build
../configure --prefix="$LFS/tools" --with-sysroot="$LFS" --target="$LFS_TGT" --disable-nls --enable-gprofng=no --disable-werror --enable-new-dtags --enable-default-hash-style=gnu
make; make install
cd "$SOURCES"; rm -rf "$D"

# --- 5.23 gcc pass 2 ---
step "gcc pass2"
download "https://ftpmirror.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz"
download "https://ftpmirror.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz"
download "https://ftpmirror.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz"
download "https://ftpmirror.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz"
D=$(extract "$SOURCES/gcc-15.2.0.tar.xz")
cd "$D"
tar -xf "$SOURCES/gmp-6.3.0.tar.xz"; mv gmp-6.3.0 gmp
tar -xf "$SOURCES/mpfr-4.2.2.tar.xz"; mv mpfr-4.2.2 mpfr
tar -xf "$SOURCES/mpc-1.3.1.tar.gz"; mv mpc-1.3.1 mpc
mkdir -v build && cd build
../configure --target="$LFS_TGT" --prefix="$LFS/tools" --with-glibc-version=2.42 --with-sysroot="$LFS" --with-newlib --without-headers --enable-default-pie --enable-default-ssp --disable-nls --disable-shared --disable-multilib --disable-threads --disable-libatomic --disable-libgomp --disable-libquadmath --disable-libssp --disable-libvtv --disable-libstdcxx --enable-languages=c,c++
make; make install
cd "$LFS/tools/bin"; ln -sf "$LFS_TGT-gcc" "$LFS_TGT-cc"
cd "$SOURCES"; rm -rf "$D"

echo "Chapter 5 cross-toolchain (full) DONE"
