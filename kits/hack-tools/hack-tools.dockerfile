# syntax=docker/dockerfile:1

# --- build stage: download the static yq binary ---
FROM debian:trixie-slim AS fetch
ARG YQ_VERSION

RUN <<EOF
set -eu
apt-get update
apt-get install -y --no-install-recommends curl ca-certificates
rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
set -eu
arch="$(dpkg --print-architecture)"   # amd64 or arm64, like the published yq binaries
mkdir -p /out/usr/local/bin
curl -fsSL -o /out/usr/local/bin/yq \
  "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${arch}"
chmod 0755 /out/usr/local/bin/yq
EOF

# --- the mixin is just a layer of files laid on top of the sandbox ---
FROM scratch
COPY --from=fetch /out/ /
