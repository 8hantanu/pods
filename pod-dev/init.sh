#!/usr/bin/env bash

set -euo pipefail

POD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${POD_DIR}/.env"

CONTAINER_NAME="${POD_DEV_CONTAINER_NAME:-pod-dev}"
IMAGE_NAME="${POD_DEV_IMAGE_NAME:-pod-dev}"
HOSTNAME_NAME="${POD_DEV_HOSTNAME:-pod-dev}"
MOUNT_PATH="/home/user/proj"
SSH_KEY_PATH="${POD_DEV_SSH_KEY_PATH:-$HOME/.ssh/pod-dev-github}"
SSH_PUB_PATH="${POD_DEV_SSH_PUB_PATH:-${SSH_KEY_PATH}.pub}"
SSH_KNOWN_HOSTS_PATH="${POD_DEV_SSH_KNOWN_HOSTS_PATH:-$HOME/.ssh/known_hosts}"

if [ -f "$CONFIG_FILE" ]; then
  set -a
  source "$CONFIG_FILE"
  set +a
fi

LOCAL_PROJ_PATH="${POD_DEV_LOCAL_PROJ_PATH:-${LOCAL_PROJ_PATH:-$HOME/Projects}}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd podman

[ -d "$LOCAL_PROJ_PATH" ] || { echo "Project path not found: ${LOCAL_PROJ_PATH}" >&2; exit 1; }
[ -f "$SSH_KEY_PATH" ] && [ -f "$SSH_PUB_PATH" ] || { echo "SSH keypair not found" >&2; exit 1; }

if podman container exists "$CONTAINER_NAME"; then
  if [ "$(podman inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
    exec podman attach "$CONTAINER_NAME"
  fi
  exec podman start -ai "$CONTAINER_NAME"
fi

exec podman run -it \
  -u 1000:1000 \
  --name "$CONTAINER_NAME" \
  --hostname "$HOSTNAME_NAME" \
  -v "${LOCAL_PROJ_PATH}:${MOUNT_PATH}" \
  -v "${SSH_KEY_PATH}:/home/user/.ssh/id_ed25519:ro" \
  -v "${SSH_PUB_PATH}:/home/user/.ssh/id_ed25519.pub:ro" \
  -v "${SSH_KNOWN_HOSTS_PATH}:/home/user/.ssh/known_hosts:ro" \
  "$IMAGE_NAME"
