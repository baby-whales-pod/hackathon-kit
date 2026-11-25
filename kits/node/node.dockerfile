# syntax=docker/dockerfile:1

# --- build stage: download and verify the official Node.js archive ---
FROM debian:trixie-slim AS fetch
ARG NODE_MAJOR=24

RUN <<EOF2
set -eu
apt-get update
apt-get install -y --no-install-recommends curl ca-certificates
rm -rf /var/lib/apt/lists/*
EOF2

RUN <<EOF2
set -eu
case "$(dpkg --print-architecture)" in
  amd64) arch=x64 ;;
  arm64) arch=arm64 ;;
  *) echo "unsupported architecture" >&2; exit 1 ;;
esac
base="https://nodejs.org/dist/latest-v${NODE_MAJOR}.x"
curl -fsSL -o /tmp/SHASUMS256.txt "$base/SHASUMS256.txt"
file="$(awk -v a="linux-$arch.tar.gz" '$2 ~ a"$" {print $2; exit}' /tmp/SHASUMS256.txt)"
curl -fsSL -o "/tmp/$file" "$base/$file"
(cd /tmp && grep " $file\$" SHASUMS256.txt | sha256sum -c -)
mkdir -p /out/usr/local
tar -xzf "/tmp/$file" -C /out/usr/local --strip-components=1 --no-same-owner \
  --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' --exclude='*/README.md'
EOF2

# --- the mixin is just a layer of files laid on top of the sandbox ---
FROM scratch
COPY --from=fetch /out/ /
