# pod-dev

Day-to-day development pod for the `pods` system.

## Setup

1. Copy the example config and customize:
   ```bash
   cp env.example .env
   ```

2. Edit `.env` with your settings:
   - Git config (name, email)
   - SSH key path
   - Project folder path
   - Tools to enable (rust, node, python, opencode)
   - Repos to clone (leave empty to skip)

3. Build the image:
   ```bash
   ./build.sh
   ```

4. Start the pod:
   ```bash
   ./init.sh
   ```

## Configuration

The `.env` file controls all settings:

| Variable | Description |
|----------|-------------|
| `GIT_USER_NAME` | Git user name |
| `GIT_USER_EMAIL` | Git email |
| `SSH_KEY_PATH` | Path to SSH private key |
| `LOCAL_PROJ_PATH` | Project folder to mount |
| `ENABLE_RUST` | Install Rust tooling |
| `ENABLE_NODE` | Install Node.js tooling |
| `ENABLE_PYTHON` | Install Python tooling |
| `ENABLE_OPENCODE` | Install OpenCode |
| `DOTS_REPO` | Dotfiles repo URL |
| `PLUG_REPO` | Plugins repo URL |
| `WIKI_REPO` | Wiki repo URL |

Leave repo URLs empty to skip cloning during build.
