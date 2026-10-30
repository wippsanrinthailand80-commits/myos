#!/usr/bin/env bash
set -e
source "$(dirname "$0")/config.sh"

download() {
  # download <url> into sources/
  local url="$1" out
  out="${SOURCES}/$(basename "$url")"
  if [ -f "$out" ]; then echo "already have $(basename "$url")"; return 0; fi
  echo "Downloading $url"
  wget -q --show-progress -O "$out" "$url" || curl -fL -o "$out" "$url"
}

extract() {
  # extract <tarball> into a fresh dir under /tmp/build, echo dir
  local tb="$1" d
  d="/tmp/build/$(basename "$tb" | sed 's/\.\(tar\.\(gz\|xz\|bz2\)\|tgz\|tar\)$//')"
  rm -rf "$d"; mkdir -p "$d"
  tar -xf "$tb" -C "$d" --strip-components=1
  echo "$d"
}
