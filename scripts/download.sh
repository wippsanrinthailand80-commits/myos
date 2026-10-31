#!/usr/bin/env bash
set -e
source "$(dirname "$0")/config.sh"

download() {
  local url="$1" out tmp
  out="${SOURCES}/$(basename "$url")"
  if [ -f "$out" ] && tar -tJf "$out" >/dev/null 2>&1 || tar -tzf "$out" >/dev/null 2>&1 || tar -tjf "$out" >/dev/null 2>&1; then
    echo "already have $(basename "$url")"; return 0
  fi
  rm -f "$out"
  echo "Downloading $url"
  tmp="${out}.part"
  if wget -q --show-progress -O "$tmp" "$url"; then
    mv "$tmp" "$out"
  elif curl -fL -o "$tmp" "$url"; then
    mv "$tmp" "$out"
  else
    rm -f "$tmp"; echo "DOWNLOAD FAILED: $url" >&2; return 1
  fi
}

extract() {
  local tb="$1" d
  d="/tmp/build/$(basename "$tb" | sed -E 's/\.(tar\.(gz|xz|bz2)|tgz|tar)$//')"
  rm -rf "$d"; mkdir -p "$d"
  tar -xf "$tb" -C "$d" --strip-components=1
  echo "$d"
}
