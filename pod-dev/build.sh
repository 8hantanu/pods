#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${POD_DEV_IMAGE_NAME:-pod-dev}"
POD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_FILE="${POD_DEV_BUILD_FILE:-${POD_DIR}/Containerfile}"
BUILD_CONTEXT="${POD_DEV_BUILD_CONTEXT:-${POD_DIR}}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd podman
echo "Building image ${IMAGE_NAME} from ${BUILD_FILE}..."
exec podman build -f "$BUILD_FILE" -t "$IMAGE_NAME" "$BUILD_CONTEXT"
