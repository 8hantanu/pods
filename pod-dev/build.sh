#!/usr/bin/env bash

set -euo pipefail

POD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${POD_DIR}/.env"
IMAGE_NAME="${POD_DEV_IMAGE_NAME:-pod-dev}"
BUILD_FILE="${POD_DEV_BUILD_FILE:-${POD_DIR}/Containerfile}"
BUILD_CONTEXT="${POD_DEV_BUILD_CONTEXT:-${POD_DIR}}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file not found: ${CONFIG_FILE}" >&2
  echo "Copy env.example to .env and customize." >&2
  exit 1
fi

set -a
source "$CONFIG_FILE"
set +a

GIT_USER_NAME="${GIT_USER_NAME:-Pod User}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-pod-user@example.com}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/pod-dev-github}"
SSH_KEY_COMMENT="${SSH_KEY_COMMENT:-pod-dev}"
LOCAL_PROJ_PATH="${LOCAL_PROJ_PATH:-$HOME/Projects}"
INSTALL_RUST="${INSTALL_RUST:-true}"
INSTALL_NODE="${INSTALL_NODE:-true}"
INSTALL_PYTHON="${INSTALL_PYTHON:-true}"
INSTALL_OPENCODE="${INSTALL_OPENCODE:-true}"
INSTALL_NVIM="${INSTALL_NVIM:-true}"
DOTS_REPO="${DOTS_REPO:-}"
PLUG_REPO="${PLUG_REPO:-}"
WIKI_REPO="${WIKI_REPO:-}"

require_cmd podman
require_cmd ssh
require_cmd ssh-keygen
require_cmd ssh-keyscan

BUILD_ARGS=()
if [ -n "$DOTS_REPO" ] || [ -n "$PLUG_REPO" ] || [ -n "$WIKI_REPO" ]; then
  BUILD_ARGS+=(--secret "id=pod_dev_github_key,src=${SSH_KEY_PATH}")
fi
BUILD_ARGS+=(
  --build-arg "GIT_USER_NAME=${GIT_USER_NAME}"
  --build-arg "GIT_USER_EMAIL=${GIT_USER_EMAIL}"
  --build-arg "INSTALL_RUST=${INSTALL_RUST}"
  --build-arg "INSTALL_NODE=${INSTALL_NODE}"
  --build-arg "INSTALL_PYTHON=${INSTALL_PYTHON}"
  --build-arg "INSTALL_OPENCODE=${INSTALL_OPENCODE}"
  --build-arg "INSTALL_NVIM=${INSTALL_NVIM}"
  --build-arg "DOTS_REPO=${DOTS_REPO}"
  --build-arg "PLUG_REPO=${PLUG_REPO}"
  --build-arg "WIKI_REPO=${WIKI_REPO}"
  -f "$BUILD_FILE"
  -t "$IMAGE_NAME"
  "$BUILD_CONTEXT"
)

echo "Building image ${IMAGE_NAME} from ${BUILD_FILE}..."
podman build "${BUILD_ARGS[@]}"
