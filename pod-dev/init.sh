#!/usr/bin/env bash

set -euo pipefail

CONTAINER_NAME="${POD_DEV_CONTAINER_NAME:-pod-dev}"
IMAGE_NAME="${POD_DEV_IMAGE_NAME:-pod-dev}"
HOSTNAME_NAME="${POD_DEV_HOSTNAME:-pod-dev}"
VOLUME_NAME="${POD_DEV_VOLUME_NAME:-pod-dev-proj}"
MOUNT_PATH="${POD_DEV_MOUNT_PATH:-/home/user/proj}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd podman
if ! podman volume exists "$VOLUME_NAME"; then
  echo "Missing required volume: ${VOLUME_NAME}" >&2
  echo "Run ./pod-dev/build.sh first." >&2
  exit 1
fi

if podman container exists "$CONTAINER_NAME"; then
  if [ "$(podman inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
    exec podman attach "$CONTAINER_NAME"
  fi
  exec podman start -ai "$CONTAINER_NAME"
fi

exec podman run -it \
  --name "$CONTAINER_NAME" \
  --hostname "$HOSTNAME_NAME" \
  -v "${VOLUME_NAME}:${MOUNT_PATH}" \
  "$IMAGE_NAME"
