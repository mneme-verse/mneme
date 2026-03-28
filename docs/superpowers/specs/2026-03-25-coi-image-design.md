# Design: coi-image.sh for mneme-dev

This design document outlines the structure and implementation of a development image management system for the `mneme` project using `coi` (Code-on-Incus).

## Goal
To provide a repeatable, automated way to create and manage a comprehensive development environment for the `mneme` Flutter project, including modern agentic tools like OpenCode and Superpowers.

## Architecture
The system consists of two shell scripts:
1. `coi-image.sh`: A management script that wraps `coi` commands for image lifecycle management (build, list, delete, shell).
2. `coi-build.sh`: A build script executed *inside* the container during image creation to provision dependencies.

## Image Definition (`mneme-dev`)
- **OS**: Ubuntu (LXD/Incus default)
- **Primary Toolchain**: Flutter SDK (Manual Tarball Installation)
- **Platform Support**:
    - **Android**: Android SDK (build-tools, platforms, licenses)
    - **Linux**: libgtk-3-dev, libblkid-dev, liblzma-dev, libgcrypt20-dev, etc.
- **Database**: `sqlite3`
- **Utilities**: `neovim`, `ripgrep`, `git`, `curl`, `unzip`, `xz-utils`, `zip`, `nodejs` (v20).
- **Agentic Tools**:
    - **OpenCode CLI**: Installed and configured.
    - **RTK**: Initialized for OpenCode.
    - **Superpowers**: Installed for OpenCode via plugin.

## Detailed Component Specifications

### 1. `coi-image.sh` (The Orchestrator)
This script is used on the host machine to manage the image lifecycle.
- **Commands**:
    - `build`: Invokes `coi build custom mneme-dev --script coi-build.sh`.
    - `shell`: Launches a session using `coi shell --image mneme-dev`.
    - `delete`: Deletes the `mneme-dev` image.
    - `list`: Lists images with the `mneme-` prefix.

### 2. `coi-build.sh` (The Environment Provisioner)
This script is executed inside the container by `coi build custom`.
- **System Update**: `apt update && apt upgrade -y`.
- **System Packages**: `apt install -y build-essential git curl neovim ripgrep sqlite3 unzip xz-utils zip libglu1-mesa-dev libgtk-3-dev libblkid-dev liblzma-dev libgcrypt20-dev`.
- **Node.js**: Install Node.js v20 via NodeSource.
- **Flutter SDK**:
    - Download latest stable tarball to `/opt/flutter`.
    - Set up global PATH in `/etc/bash.bashrc`.
    - `flutter config --no-analytics`.
- **Android SDK**:
    - Download `cmdline-tools` to `/opt/android-sdk`.
    - Install `platforms;android-35`, `build-tools;35.0.0`, `platform-tools`.
    - Accept all Android licenses automatically.
- **Agentic Tools Setup**:
    - **OpenCode**: `curl -fsSL https://opencode.ai/install | bash`.
    - **RTK**: Install via curl script, move to `/usr/local/bin`, and `rtk init -g --opencode`.
    - **Superpowers**:
        - Configure `~/.config/opencode/opencode.json` with `superpowers@git+https://github.com/obra/superpowers.git`.
- **Cleanup**: `apt clean` and remove temporary downloads.

## Validation Strategy
- Verify `coi-image.sh build` completes without errors.
- Inside the container, verify:
    - `flutter doctor -v` shows Flutter and Android SDK are correctly configured.
    - `opencode --version` works.
    - `rtk --version` works.
    - `sqlite3 --version`, `nvim --version`, `rg --version` work.
