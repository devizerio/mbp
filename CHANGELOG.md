# Changelog

All notable changes to mbp will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - 2026-03-27

### Added
- Initial release of mbp — Devizer MacBook Pro provisioning tool
- 13 setup modules: xcode, homebrew, shell, mise, dotfiles, git, ssh, secrets, docker, ai-tools, macos-defaults, apps, dev-dirs
- Modular profile system with INI-style `.conf` files (devizer-full, client-minimal, personal)
- Split Brewfiles: Brewfile.core, .dev, .ai, .apps, .personal
- Dual-mode state tracking: plain-text for bootstrap modules 01-02, JSON from module 03 onward
- Drift detection via `mbp audit` (brew, mise, dotfiles, macOS defaults)
- Interactive onboarding tour via `mbp tour`
- Self-update via `mbp update`
- One-liner bootstrap via `install.sh`
- mise replacing asdf as runtime version manager with automatic migration
- Devizer brand color (#1D4ED8 blue-700) applied consistently across all terminal output
- GitHub Actions CI running shellcheck at warning level
- Oh My Zsh, global dotfiles (zshrc, gitconfig, ssh-config, vimrc, tool-versions)
- macOS defaults: Dock autohide, Finder extensions, keyboard repeat, screenshot path, dark mode
- Developer directory structure: ~/Developer/Clients, agents, ai, playground, Routine
