#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${POD_DEV_IMAGE_NAME:-pod-dev}"
VOLUME_NAME="${POD_DEV_VOLUME_NAME:-pod-dev-proj}"
POD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_FILE="${POD_DEV_BUILD_FILE:-${POD_DIR}/Containerfile}"
BUILD_CONTEXT="${POD_DEV_BUILD_CONTEXT:-${POD_DIR}}"
DEFAULT_GIT_USER_NAME="${POD_DEV_GIT_USER_NAME:-$(git config --global --get user.name 2>/dev/null || true)}"
DEFAULT_GIT_USER_EMAIL="${POD_DEV_GIT_USER_EMAIL:-$(git config --global --get user.email 2>/dev/null || true)}"
DEFAULT_INSTALL_RUST="${POD_DEV_INSTALL_RUST:-y}"
DEFAULT_INSTALL_NODEJS="${POD_DEV_INSTALL_NODEJS:-y}"
DEFAULT_INSTALL_PYTHON="${POD_DEV_INSTALL_PYTHON:-y}"
DEFAULT_INSTALL_NVIM="${POD_DEV_INSTALL_NVIM:-y}"
DEFAULT_INSTALL_OPENCODE="${POD_DEV_INSTALL_OPENCODE:-y}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

prompt_value() {
  local prompt="$1"
  local default_value="$2"
  local response
  if [ -n "$default_value" ]; then
    printf "%s [%s]: " "$prompt" "$default_value" >&2
  else
    printf "%s: " "$prompt" >&2
  fi
  IFS= read -r response
  if [ -z "$response" ]; then
    response="$default_value"
  fi
  printf '%s' "$response"
}

prompt_yes_no() {
  local prompt="$1"
  local default_value="$2"
  local response
  while true; do
    printf "%s [%s]: " "$prompt" "$default_value" >&2
    IFS= read -r response
    response="${response:-$default_value}"
    case "$response" in
      y|Y|yes|YES) printf '1'; return 0 ;;
      n|N|no|NO) printf '0'; return 0 ;;
      *) echo "Enter y or n." >&2 ;;
    esac
  done
}

require_cmd podman
GIT_USER_NAME="$(prompt_value "Git user.name" "$DEFAULT_GIT_USER_NAME")"
GIT_USER_EMAIL="$(prompt_value "Git user.email" "$DEFAULT_GIT_USER_EMAIL")"
INSTALL_RUST="$(prompt_yes_no "Install Rust tooling" "$DEFAULT_INSTALL_RUST")"
INSTALL_NODEJS="$(prompt_yes_no "Install Node.js tooling" "$DEFAULT_INSTALL_NODEJS")"
INSTALL_PYTHON="$(prompt_yes_no "Install Python tooling" "$DEFAULT_INSTALL_PYTHON")"
INSTALL_NVIM="$(prompt_yes_no "Install Neovim" "$DEFAULT_INSTALL_NVIM")"
INSTALL_OPENCODE="$(prompt_yes_no "Install OpenCode" "$DEFAULT_INSTALL_OPENCODE")"

podman volume create --ignore "$VOLUME_NAME" >/dev/null
echo "Ensured volume ${VOLUME_NAME} exists."
echo "Building image ${IMAGE_NAME} from ${BUILD_FILE}..."
exec podman build \
  --log-level=warn \
  --build-arg "GIT_USER_NAME=${GIT_USER_NAME}" \
  --build-arg "GIT_USER_EMAIL=${GIT_USER_EMAIL}" \
  --build-arg "INSTALL_RUST=${INSTALL_RUST}" \
  --build-arg "INSTALL_NODEJS=${INSTALL_NODEJS}" \
  --build-arg "INSTALL_PYTHON=${INSTALL_PYTHON}" \
  --build-arg "INSTALL_NVIM=${INSTALL_NVIM}" \
  --build-arg "INSTALL_OPENCODE=${INSTALL_OPENCODE}" \
  -f "$BUILD_FILE" \
  -t "$IMAGE_NAME" \
  "$BUILD_CONTEXT"
