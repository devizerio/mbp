# mbp — MacBook Pro setup

mbp is a modular shell-script provisioning tool for Devizer's MacBook Pros.
It is **not** Ansible, Chef, or Nix — it is bash scripts that are meant to be
read by humans (and Claude Code).

## Architecture

```
bin/mbp              — CLI entry point (subcommands: setup, audit, tour, update, status)
bin/mbp-prompts.mjs  — Node.js interactive prompts (@clack/prompts)
lib/
  core.sh            — logging, color, idempotency helpers, mbp_run_module, module path resolution
  platform.sh        — macOS version detection, Homebrew prefix
  state.sh           — state R/W (plain-text for modules 01-02, JSON from module 03 onward)
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
  11-macos-defaults.sh — Dock, Finder, keyboard, screenshot, widget defaults
  12-apps.sh         — verify cask installs + VS Code CLI setup
  13-dev-dirs.sh     — ~/.mbp infrastructure dirs
dotfiles/
  zshrc              — Oh My Zsh config, mise activation, client() helper
  gitconfig          — git identity, gh credential, GPG signing stub
  ssh-config         — 1Password agent, github.com host, config.d Include
  tool-versions      — global mise runtimes
  vimrc              — minimal vim config
brewfiles/
  Brewfile.core      — essentials every machine needs
  Brewfile.dev       — developer tools (mise, bun, docker, VS Code, cloud CLIs)
  Brewfile.ai        — AI tooling (bundled only if ai-tools module selected)
  Brewfile.apps      — desktop applications (bundled only if apps module selected)
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

### Module selection

On first run, an interactive picker lets the user choose which modules to install.
The selection is saved to `~/.mbp/selected_modules.txt` (plain text, one module per
line) since jq is not yet available. Module 03's state migration copies this into
`state.json` under a `selected_modules` array. On re-runs, the saved selection is used.
`--force` re-triggers the picker.

Module 02 (homebrew) reads `selected_modules.txt` to determine which Brewfiles to
bundle: `core` and `dev` always run; `ai` only if `ai-tools` is selected; `apps` only
if `apps` is selected.

## Interactive prompts (@clack/prompts)

All interactive user input (module picker, confirmations, tour) uses `@clack/prompts`
via `bin/mbp-prompts.mjs` when Node.js is available. Falls back to bash `read` prompts
on fresh Macs where Node isn't installed yet.

The Node script communicates with bash via stdout markers (e.g. `__MBP_MODULES_START__`,
`__MBP_CONFIRM__=yes`). The bash caller parses these markers and displays the rest.

Detection: `mbp_has_node_prompts()` checks for `node` binary + `node_modules/@clack/prompts`.

## Module conventions

Each module:
1. Is sourced by `mbp_run_module` from `bin/mbp`
2. Has access to all `lib/*.sh` functions
3. Should be idempotent — check before acting
4. Should call `state_set_module_ok` / `state_set_module_error` at end
5. Should use `mbp_log_step`, `mbp_log_ok`, `mbp_log_warn`, `mbp_log_error` for output
6. Must NOT call `exit` — return non-zero to signal failure

Modules 01 and 02 use `state_txt_set` instead of the JSON functions.

## Adding a module

1. Create `modules/NN-name.sh`
2. Add the module name to `MBP_DEFAULT_MODULES` in `bin/mbp`
3. Add a description to `MBP_MODULE_DESC` in `bin/mbp`
4. Add a tour content file at `tour/content/NN-name.md` if needed
5. Add a step to `tour/steps.sh` ALL_STEPS array

## Testing

Run `shellcheck` against all scripts:

  shellcheck bin/mbp lib/*.sh modules/*.sh tour/steps.sh install.sh

Re-run individual modules during development:

  MBP_FORCE=1 mbp setup --module mise

## Key environment variables

  MBP_REPO               — path to this repository (set by bin/mbp)
  MBP_FORCE=1            — re-run completed modules
  NO_COLOR=1             — disable ANSI color output
  MBP_PROFILE_BREWFILES  — space-separated Brewfile names (set from defaults in bin/mbp)
  MBP_PROFILE_MISE_TOOLS — space-separated tool@version pairs (set from defaults in bin/mbp)

## Brand

Devizer brand color: ANSI 256 color 26 (blue-700, #1D4ED8)
Used via `$MBP_COLOR_BRAND` from `lib/core.sh`.
