#!/usr/bin/env bash

set -euo pipefail

HOME_DIR="${HOME:-/home/user}"
DOTS_DIR="${HOME_DIR}/dots"
DOTS_REPO="${POD_DEV_DOTS_REPO:-$(git config --global --get poddev.dotsRepo || true)}"

if [ -z "${DOTS_REPO}" ]; then
  echo "No dots repository configured. Set POD_DEV_DOTS_REPO or git config --global poddev.dotsRepo." >&2
  exit 1
fi

mkdir -p "${HOME_DIR}/.ssh" "${HOME_DIR}/.config/nvim"
chmod 700 "${HOME_DIR}/.ssh"

if ! ssh-keygen -F github.com >/dev/null 2>&1; then
  ssh-keyscan -H github.com >> "${HOME_DIR}/.ssh/known_hosts"
  chmod 600 "${HOME_DIR}/.ssh/known_hosts"
fi

if [ ! -d "${DOTS_DIR}/.git" ]; then
  git clone "${DOTS_REPO}" "${DOTS_DIR}"
else
  git -C "${DOTS_DIR}" pull --ff-only
fi

ln -snf "${DOTS_DIR}/.vimrc" "${HOME_DIR}/.vimrc"
ln -snf "${DOTS_DIR}/.tmux.conf" "${HOME_DIR}/.tmux.conf"
ln -snf "${DOTS_DIR}/.nvimrc" "${HOME_DIR}/.config/nvim/init.vim"

echo "Dotfiles installed from ${DOTS_REPO}."
