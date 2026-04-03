#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${POD_DEV_IMAGE_NAME:-pod-dev}"
VOLUME_NAME="${POD_DEV_VOLUME_NAME:-pod-dev-proj}"
POD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_FILE="${POD_DEV_BUILD_FILE:-${POD_DIR}/Containerfile}"
BUILD_CONTEXT="${POD_DEV_BUILD_CONTEXT:-${POD_DIR}}"
SSH_KEY_PATH="${POD_DEV_SSH_KEY_PATH:-$HOME/.ssh/pod-dev-github}"
SSH_KEY_COMMENT="${POD_DEV_SSH_KEY_COMMENT:-pod-dev-github}"
DEFAULT_GIT_USER_NAME="${POD_DEV_GIT_USER_NAME:-$(git config --global --get user.name 2>/dev/null || true)}"
DEFAULT_GIT_USER_EMAIL="${POD_DEV_GIT_USER_EMAIL:-$(git config --global --get user.email 2>/dev/null || true)}"
DEFAULT_ENABLE_GITHUB_SSH="${POD_DEV_ENABLE_GITHUB_SSH:-n}"
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

verify_github_ssh() {
  local key_path="$1"
  if ssh -o BatchMode=yes -o ConnectTimeout=10 -i "$key_path" -T git@github.com; then
    return 0
  fi
  local ssh_status=$?
  if [ "$ssh_status" -eq 1 ]; then
    return 0
  fi
  return "$ssh_status"
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
require_cmd ssh
require_cmd ssh-keygen
require_cmd ssh-keyscan
GIT_USER_NAME="$(prompt_value "Git user.name" "$DEFAULT_GIT_USER_NAME")"
GIT_USER_EMAIL="$(prompt_value "Git user.email" "$DEFAULT_GIT_USER_EMAIL")"
ENABLE_GITHUB_SSH="$(prompt_yes_no "Use GitHub SSH credentials during build" "$DEFAULT_ENABLE_GITHUB_SSH")"
INSTALL_RUST="$(prompt_yes_no "Install Rust tooling" "$DEFAULT_INSTALL_RUST")"
INSTALL_NODEJS="$(prompt_yes_no "Install Node.js tooling" "$DEFAULT_INSTALL_NODEJS")"
INSTALL_PYTHON="$(prompt_yes_no "Install Python tooling" "$DEFAULT_INSTALL_PYTHON")"
INSTALL_NVIM="$(prompt_yes_no "Install Neovim" "$DEFAULT_INSTALL_NVIM")"
INSTALL_OPENCODE="$(prompt_yes_no "Install OpenCode" "$DEFAULT_INSTALL_OPENCODE")"

TEMP_SECRET_FILE="$(mktemp /tmp/pod-dev-github-key.XXXXXX)"
cleanup() {
  rm -f "$TEMP_SECRET_FILE"
}
trap cleanup EXIT

if [ "$ENABLE_GITHUB_SSH" = "1" ]; then
  mkdir -p "$(dirname "$SSH_KEY_PATH")"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  if [ ! -f "$SSH_KEY_PATH" ]; then
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "$SSH_KEY_COMMENT"
  fi
  if [ ! -f "${SSH_KEY_PATH}.pub" ]; then
    echo "Public key not found at ${SSH_KEY_PATH}.pub" >&2
    exit 1
  fi
  if ! ssh-keygen -F github.com >/dev/null 2>&1; then
    ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts"
  fi
  echo >&2
  echo "Add this SSH public key to GitHub:" >&2
  echo >&2
  cat "${SSH_KEY_PATH}.pub" >&2
  echo >&2
  echo "GitHub path: Settings > SSH and GPG keys > New SSH key" >&2
  echo >&2
  while true; do
    printf "Press Enter once the key has been added to GitHub, or type 'skip' to try the build anyway: " >&2
    IFS= read -r response
    case "${response:-}" in
      ""|"skip") break ;;
      *) echo "Waiting for confirmation." >&2 ;;
    esac
  done
  echo "Verifying GitHub SSH access..." >&2
  if ! verify_github_ssh "$SSH_KEY_PATH"; then
    echo "GitHub SSH check failed. Make sure the key is added before retrying." >&2
    exit 1
  fi
  cp "$SSH_KEY_PATH" "$TEMP_SECRET_FILE"
  chmod 600 "$TEMP_SECRET_FILE"
else
  : > "$TEMP_SECRET_FILE"
  chmod 600 "$TEMP_SECRET_FILE"
fi

podman volume create --ignore "$VOLUME_NAME" >/dev/null
echo "Ensured volume ${VOLUME_NAME} exists."
echo "Building image ${IMAGE_NAME} from ${BUILD_FILE}..."
podman build \
  --log-level=warn \
  --secret "id=pod_dev_github_key,src=${TEMP_SECRET_FILE}" \
  --build-arg "GIT_USER_NAME=${GIT_USER_NAME}" \
  --build-arg "GIT_USER_EMAIL=${GIT_USER_EMAIL}" \
  --build-arg "ENABLE_GITHUB_SSH=${ENABLE_GITHUB_SSH}" \
  --build-arg "INSTALL_RUST=${INSTALL_RUST}" \
  --build-arg "INSTALL_NODEJS=${INSTALL_NODEJS}" \
  --build-arg "INSTALL_PYTHON=${INSTALL_PYTHON}" \
  --build-arg "INSTALL_NVIM=${INSTALL_NVIM}" \
  --build-arg "INSTALL_OPENCODE=${INSTALL_OPENCODE}" \
  -f "$BUILD_FILE" \
  -t "$IMAGE_NAME" \
  "$BUILD_CONTEXT"
