# syntax=docker/dockerfile:1
# vscode-ssh: the shell template
FROM docker/sandbox-templates:shell

USER root

# What the VS Code server expects on a Remote-SSH host
RUN <<EOF
set -eux
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  libstdc++6 tar gzip curl wget ca-certificates procps git
rm -rf /var/lib/apt/lists/*
EOF

USER agent

# Default machine settings for the VS Code server
RUN --mount=type=bind,target=/tmp/kit <<EOF
set -eux
install -D -m 0644 /tmp/kit/config/machine-settings.json \
  /home/agent/.vscode-server/data/Machine/settings.json
EOF

WORKDIR /home/agent/workspace
