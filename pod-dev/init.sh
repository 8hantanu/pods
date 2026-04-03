#!/usr/bin/env bash

set -euo pipefail

CONTAINER_NAME="${POD_DEV_CONTAINER_NAME:-pod-dev}"
IMAGE_NAME="${POD_DEV_IMAGE_NAME:-pod-dev}"
HOSTNAME_NAME="${POD_DEV_HOSTNAME:-pod-dev}"
VOLUME_NAME="${POD_DEV_VOLUME_NAME:-pod-dev-proj}"
MOUNT_PATH="${POD_DEV_MOUNT_PATH:-/home/user/proj}"
SSH_KEY_PATH="${POD_DEV_SSH_KEY_PATH:-$HOME/.ssh/pod-dev-github}"
SSH_PUB_PATH="${POD_DEV_SSH_PUB_PATH:-${SSH_KEY_PATH}.pub}"
SSH_KNOWN_HOSTS_PATH="${POD_DEV_SSH_KNOWN_HOSTS_PATH:-$HOME/.ssh/known_hosts}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

container_has_ssh_mount() {
  local target="$1"
  podman inspect -f '{{range .Mounts}}{{println .Destination}}{{end}}' "$CONTAINER_NAME" | grep -qx "$target"
}

require_cmd podman
if ! podman volume exists "$VOLUME_NAME"; then
  echo "Missing required volume: ${VOLUME_NAME}" >&2
  echo "Run ./pod-dev/build.sh first." >&2
  exit 1
fi

IMAGE_GITHUB_SSH_ENABLED="$(podman image inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$IMAGE_NAME" | grep '^POD_DEV_GITHUB_SSH_ENABLED=' | tail -n 1 | cut -d= -f2- || true)"
IMAGE_GITHUB_SSH_ENABLED="${IMAGE_GITHUB_SSH_ENABLED:-0}"

SSH_ARGS=()
if [ "$IMAGE_GITHUB_SSH_ENABLED" = "1" ]; then
  if [ ! -f "$SSH_KEY_PATH" ] || [ ! -f "$SSH_PUB_PATH" ]; then
    echo "Image ${IMAGE_NAME} expects GitHub SSH, but the host keypair is missing." >&2
    echo "Expected ${SSH_KEY_PATH} and ${SSH_PUB_PATH}." >&2
    echo "Rebuild with GitHub SSH disabled or restore the keypair." >&2
    exit 1
  fi
  SSH_ARGS+=(-v "${SSH_KEY_PATH}:/home/user/.ssh/id_ed25519:ro")
  SSH_ARGS+=(-v "${SSH_PUB_PATH}:/home/user/.ssh/id_ed25519.pub:ro")
  if [ -f "$SSH_KNOWN_HOSTS_PATH" ]; then
    SSH_ARGS+=(-v "${SSH_KNOWN_HOSTS_PATH}:/home/user/.ssh/known_hosts:ro")
  fi
fi

if podman container exists "$CONTAINER_NAME"; then
  if [ "$IMAGE_GITHUB_SSH_ENABLED" = "1" ]; then
    if ! container_has_ssh_mount '/home/user/.ssh/id_ed25519'; then
      echo "Existing container ${CONTAINER_NAME} does not have the required GitHub SSH mount." >&2
      echo "Remove it and run ./pod-dev/init.sh again to recreate it from the current image." >&2
      exit 1
    fi
  elif container_has_ssh_mount '/home/user/.ssh/id_ed25519'; then
    echo "Existing container ${CONTAINER_NAME} still has GitHub SSH mounted, but image ${IMAGE_NAME} does not expect it." >&2
    echo "Remove it and run ./pod-dev/init.sh again to recreate it from the current image." >&2
    exit 1
  fi
  if [ "$(podman inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
    exec podman attach "$CONTAINER_NAME"
  fi
  exec podman start -ai "$CONTAINER_NAME"
fi

exec podman run -it \
  --name "$CONTAINER_NAME" \
  --hostname "$HOSTNAME_NAME" \
  -v "${VOLUME_NAME}:${MOUNT_PATH}" \
  "${SSH_ARGS[@]}" \
  "$IMAGE_NAME"
