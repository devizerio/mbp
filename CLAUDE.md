# mbp — MacBook Pro setup

mbp is a modular shell-script provisioning tool for Devizer's MacBook Pros.
It is **not** Ansible, Chef, or Nix — it is bash scripts that are meant to be
read by humans (and Claude Code).

## Architecture

```
bin/mbp              — CLI entry point (subcommands: setup, audit, tour, update, status)
lib/
  core.sh            — logging, color, idempotency helpers, mbp_run_module
  platform.sh        — macOS version detection, Homebrew prefix
  state.sh           — state R/W (plain-text for modules 01-02, JSON from module 03 onward)
  profile.sh         — INI-style .conf parser, module path resolution
  audit.sh           — drift detection (brew, mise, dotfiles, macOS defaults)
modules/
  01-xcode.sh        — Xcode CLT (critical — halts on failure)
  02-homebrew.sh     — Homebrew + brew bundle (critical — halts on failure)
  03-shell.sh        — Oh My Zsh, default shell         [migrates state to JSON]
  04-mise.sh         — runtime version manager (replaces asdf)
  05-dotfiles.sh     — symlink dotfiles, create ~/.zshrc.local
  06-git.sh          — gh credential helper, optional GPG signing
  07-ssh.sh          — key permissions, config.d directory
  08-secrets.sh      — 1Password CLI
  09-docker.sh       — Docker Desktop
  10-ai-tools.sh     — Claude Code + gstack
  11-macos-defaults.sh — Dock, Finder, keyboard, screenshot defaults
  12-apps.sh         — verify cask installs from active profile
  13-dev-dirs.sh     — ~/Developer structure, ~/.mbp dirs
dotfiles/
  zshrc              — Oh My Zsh config, mise activation, client() helper
  gitconfig          — git identity, gh credential, GPG signing stub
  ssh-config         — 1Password agent, github.com host, config.d Include
  tool-versions      — global mise runtimes
  vimrc              — minimal vim config
profiles/
  devizer-full.conf  — all modules, full Brewfiles
  client-minimal.conf — subset for client machines
  personal.conf      — full + personal tools
brewfiles/
  Brewfile.core      — essentials every machine needs
  Brewfile.dev       — developer tools (mise, bun, docker, cloud CLIs)
  Brewfile.ai        — AI tooling
  Brewfile.apps      — desktop applications
  Brewfile.personal  — personal preferences
tour/
  steps.sh           — interactive walkthrough (mbp tour)
  content/           — markdown files shown in the tour (one per module)
```

## State design

The bootstrap problem: jq (needed for JSON) is installed by module 02. Modules 01-02
use plain-text state (`~/.mbp/state.txt`, format: `module=status:exit_code:timestamp`).
Module 03 triggers migration to JSON (`~/.mbp/state.json`) via `state_migrate_from_txt`.

State is keyed by module name (e.g. `homebrew`, `mise`). A completed module has status
`ok` and is skipped on re-runs unless `MBP_FORCE=1`.

## Module conventions

Each module:
1. Is sourced by `mbp_run_module` from `bin/mbp`
2. Has access to all `lib/*.sh` functions
3. Should be idempotent — check before acting
4. Should call `state_set_module_ok` / `state_set_module_error` at end
5. Should use `mbp_log_step`, `mbp_log_ok`, `mbp_log_warn`, `mbp_log_error` for output
6. Must NOT call `exit` — return non-zero to signal failure

Modules 01 and 02 use `state_txt_set` instead of the JSON functions.

## Profile format

```ini
format = 1
modules = homebrew,mise,shell,dotfiles,git,ssh,secrets,docker,ai-tools,macos-defaults,apps,dev-dirs
brewfiles = Brewfile.core Brewfile.dev Brewfile.ai Brewfile.apps
mise_tools = nodejs:22.0.0 ruby:3.3.0 python:3.12.0
```

## Adding a module

1. Create `modules/NN-name.sh`
2. Add `name` to the relevant profile's `modules =` line
3. Add a tour content file at `tour/content/NN-name.md` if needed
4. Add a step to `tour/steps.sh` ALL_STEPS array

## Testing

Run `shellcheck` against all scripts:

  shellcheck bin/mbp lib/*.sh modules/*.sh tour/steps.sh install.sh

Re-run individual modules during development:

  MBP_FORCE=1 mbp setup --module mise

## Key environment variables

  MBP_REPO         — path to this repository (set by bin/mbp)
  MBP_FORCE=1      — re-run completed modules
  NO_COLOR=1       — disable ANSI color output
  MBP_PROFILE_MODULES   — space-separated module names (set by profile_load)
  MBP_PROFILE_BREWFILES — space-separated Brewfile names
  MBP_PROFILE_MISE_TOOLS — space-separated tool:version pairs

## Brand

Devizer brand color: ANSI 256 color 26 (blue-700, #1D4ED8)
Used via `$MBP_COLOR_BRAND` from `lib/core.sh`.
