# pod-dev

Day-to-day development pod for the `pods` system.

## Build

Use the helper script:

```bash
./pod-dev/build.sh
```

The build script ensures the `pod-dev-proj` named volume exists and then
asks for:

- `git user.name`
- `git user.email`
- whether to install Rust tooling
- whether to install Node.js tooling
- whether to install Python tooling
- whether to install Neovim
- whether to install OpenCode

It then ensures the `pod-dev-proj` named volume exists and builds the
image with those settings.

Manual build:

```bash
podman pull docker.io/library/debian:bookworm-slim
podman volume create --ignore pod-dev-proj
podman build \
  --build-arg GIT_USER_NAME="Your Name" \
  --build-arg GIT_USER_EMAIL="you@example.com" \
  --build-arg INSTALL_RUST=1 \
  --build-arg INSTALL_NODEJS=1 \
  --build-arg INSTALL_PYTHON=1 \
  --build-arg INSTALL_NVIM=1 \
  --build-arg INSTALL_OPENCODE=1 \
  -f pod-dev/Containerfile \
  -t pod-dev \
  pod-dev
```

The image pulls the current Neovim stable release tarball at build time
rather than building Neovim from source. It also prepares this home
layout during the image build:

- `/home/user/proj`
- `/home/user/wiki`
- `/home/user/ship`
- `/home/user/reqs`
- `/home/user/ship/control/dots`
- `/home/user/ship/control/plug`

It clones `wiki`, `dots`, and `plug` during the image build, runs
`stow` from `ship/control/dots` so your home directory is configured
before first boot, writes `/home/user/.config/nvim/init.lua` so Neovim
sources `~/.vimrc`, and exposes `plug` through `PLUG_PATH` and `PATH`.

The image also installs `opencode` during build using OpenCode's
official npm package when enabled, and can also include general Node.js
and Python toolchains for the pod when requested.

## Run

Use the init script:

```bash
./pod-dev/init.sh
```

It creates and runs `pod-dev` on first use, or reattaches to the
existing container on later runs. If the `pod-dev-proj` volume does not
exist yet, it tells you to run `./pod-dev/build.sh` first.

Manual run:

```bash
podman run -it --name pod-dev --hostname pod-dev \
  -v "pod-dev-proj:/home/user/proj" \
  pod-dev
```

`/home/user/proj` persists in the named volume. On the first run, Podman
copies the image content at that mountpoint into the empty named volume
by default. The rest of the baked-in workspace stays under `/home/user`
outside that volume.

## Reattach

```bash
podman start -ai pod-dev
```
