#!/usr/bin/env sh
# Installs Node.js (official binary from nodejs.org) INSIDE a sandbox, because the
# Copilot image does not ship it. Run it from the host, at the repository root:
#   sbx exec -i <sandbox> sh -s < scripts/install-node.sh
# (the script goes through standard input, so the sandbox working directory does not matter)
# Network: nodejs.org only (allowed by the sbx "balanced" policy).
# With deny-all: sbx policy allow network nodejs.org, or install Node before closing the network.
set -eu
NODE_MAJOR="${NODE_MAJOR:-24}"

if command -v node >/dev/null 2>&1; then
  echo "Node.js already installed: $(node --version)"; exit 0
fi

case "$(uname -m)" in
  x86_64|amd64)  arch=x64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

base="https://nodejs.org/dist/latest-v${NODE_MAJOR}.x"
sums="$(curl -fsSL "$base/SHASUMS256.txt")"
file="$(printf '%s\n' "$sums" | awk -v a="linux-$arch.tar.gz" '$2 ~ a"$" {print $2; exit}')"
[ -n "$file" ] || { echo "Node archive not found in $base" >&2; exit 1; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
echo "Downloading $file..."
curl -fsSL -o "$tmp/$file" "$base/$file"
# Check the checksum published by nodejs.org
(cd "$tmp" && printf '%s\n' "$sums" | grep " $file\$" | sha256sum -c - >/dev/null) \
  || { echo "invalid SHA-256 checksum" >&2; exit 1; }

# Into /usr/local when running as root or when sudo works without a password,
# otherwise into ~/.local (already on the PATH of sbx sandboxes).
if [ "$(id -u)" = 0 ]; then SUDO=""; prefix=/usr/local
elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then SUDO="sudo"; prefix=/usr/local
else SUDO=""; prefix="$HOME/.local"; mkdir -p "$prefix"
fi
$SUDO tar -xzf "$tmp/$file" -C "$prefix" --strip-components=1 --no-same-owner \
  --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' --exclude='*/README.md'
PATH="$prefix/bin:$PATH"
echo "Node.js installed in $prefix: $(node --version), npm $(npm --version)"
