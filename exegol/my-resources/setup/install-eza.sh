#!/bin/bash

# Temporary script to install eza quickly from precompiled binaries.
# As installing with apt actually create package conflict and installing with
# cargo is much too long.
# Apt install should be reevaluate on each exegol update.
#
set -euo pipefail

REPO="eza-community/eza"

target="x86_64-unknown-linux-gnu"

# Get latest tag (jq optional)
latest_json="$(curl -fsSL https://api.github.com/repos/$REPO/releases/latest)"
tag=$(printf '%s' "$latest_json" | { command -v jq >/dev/null 2>&1 && jq -r .tag_name || sed -n 's/.*"tag_name": *"\(v\?[0-9][^"]*\)".*/\1/p'; } | head -n1)
[ -n "$tag" ] || {
  echo "Cannot determine latest tag" >&2
  exit 1
}
version="${tag#v}"

asset="eza_${target}.tar.gz"

# Find asset URL
asset_url=$(
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$latest_json" | jq -r --arg name "$asset" '.assets[] | select(.name==$name) | .browser_download_url'
  else
    printf '%s' "$latest_json" | grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4 | grep "/${asset}$" | head -n1
  fi
)

[ -n "$asset_url" ] || {
  echo "Asset not found: $asset" >&2
  exit 1
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "Downloading $asset_url"
curl -fL --retry 3 -o "$tmpdir/$asset" "$asset_url"

mkdir "$tmpdir/eza"

echo "Extracting binary"
tar -xzf "$tmpdir/$asset" -C "$tmpdir/eza"

install_dir="/usr/local/bin"

install -m 0755 "$tmpdir/eza/eza" "$install_dir/eza"

echo -n "Installed: "
"$install_dir/eza" --version

## Download and install zsh completion
curl -fsSL "https://raw.githubusercontent.com/eza-community/eza/${tag}/completions/zsh/_eza" \
  -o /usr/share/zsh/vendor-completions/_eza
