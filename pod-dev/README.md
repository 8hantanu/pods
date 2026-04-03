# pod-dev

Day-to-day development pod for the `pods` system.

## Build

Use the helper script:

```bash
./pod-dev/build.sh
```

Manual build:

```bash
podman pull docker.io/library/debian:bookworm-slim
podman build -f pod-dev/Containerfile -t pod-dev pod-dev
```

The image installs a pinned official Neovim release tarball rather than
building Neovim from source.

## Run

Create the persistent project volume once:

```bash
podman volume create pod-dev-proj
```

Then run the pod:

```bash
podman run -it --name pod-dev --hostname pod-dev \
  -v "pod-dev-proj:/home/user/proj" \
  -v "$HOME/.ssh/pod-dev-github:/home/user/.ssh/id_ed25519:ro" \
  -v "$HOME/.ssh/pod-dev-github.pub:/home/user/.ssh/id_ed25519.pub:ro" \
  pod-dev
```

Clone working repositories into `/home/user/proj`. The named volume
keeps them even if you remove and recreate the container.

## Reattach

```bash
podman start -ai pod-dev
```

## Dotfiles

Inside the running container:

```bash
pod-dev-init
```

That command clones or updates the configured `dots` repo and wires the
shell, tmux, and Neovim symlinks.
