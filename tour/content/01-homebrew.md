# Homebrew

**The package manager for macOS.** Everything else depends on this.

Homebrew is how mbp installs nearly all your developer tools — from CLI
utilities to full desktop applications. It keeps everything organized,
updatable, and easy to remove.

## What was installed

mbp uses split **Brewfiles** to install packages in logical groups:

  - **Brewfile.core**  — essentials: git, gh, jq, gnupg, vim, tmux, curl
  - **Brewfile.dev**   — runtime tools: mise, bun, docker, cloud CLIs
  - **Brewfile.ai**    — AI tooling support
  - **Brewfile.apps**  — desktop apps: ngrok, secretive, xcodes
  - **Brewfile.personal** — personal extras

Your active profile controls which Brewfiles are used.

## Useful commands

  brew list              — see everything installed
  brew info <package>    — details about any package
  brew upgrade           — update all packages
  brew cleanup           — reclaim disk space

  mbp audit              — checks for Brewfile drift

## Lock-free installs

mbp runs `brew bundle --no-lock --no-upgrade` so installs are fast and
idempotent. Run `mbp setup` again anytime — already-installed packages
are skipped.

## Homebrew prefix

Your Homebrew is at:
  /opt/homebrew     (Apple Silicon)
  /usr/local        (Intel)
