# mbp

**A MacBook Pro setup script for the modern developer.** Built by [Devizer](https://devizer.io).

One command takes a bare Mac from factory reset to fully provisioned — with
mise runtimes, AI tools, SSH key management, and drift detection that keeps
everything honest.

```
bash <(curl -fsSL https://raw.githubusercontent.com/devizerio/mbp/main/install.sh)
```

---

## What it does

On first run, an interactive module picker lets you choose what to install.
Your selection is saved so re-runs skip the picker and only install what's
missing.

| # | Module | What it sets up |
|---|--------|----------------|
| 01 | xcode | Xcode Command Line Tools |
| 02 | homebrew | Homebrew + packages from Brewfiles |
| 03 | shell | Oh My Zsh, Homebrew zsh as default shell |
| 04 | mise | Runtime version manager (Node, Ruby, Python, Bun) |
| 05 | dotfiles | zshrc, gitconfig, ssh-config, vimrc (symlinked) |
| 06 | git | GitHub CLI credential helper, SSH commit signing |
| 07 | ssh | Key permissions, config.d include pattern, Keychain persistence |
| 08 | secrets | 1Password CLI |
| 09 | docker | Docker Desktop |
| 10 | ai-tools | Claude Code + gstack skills |
| 11 | macos-defaults | Dock, Finder, keyboard, screenshots, widgets |
| 12 | apps | Verify cask installations + VS Code CLI |
| 13 | dev-dirs | `~/Developer` structure, `~/.mbp` dirs |

Each module is **idempotent** — run `mbp setup` again at any time to install
what's missing and skip what's already done.

---

## CLI reference

```
mbp setup [--module NAME] [--force]
mbp audit
mbp ssh
mbp status
mbp tour
mbp update
mbp --version
mbp --help
```

### `mbp setup`

Provisions the machine. On first run you'll see an interactive picker to
choose which modules to install (xcode and homebrew are always required).
On subsequent runs, your saved selection is used.

```bash
mbp setup                          # run all selected modules
mbp setup --module mise            # run only the mise module
mbp setup --module mise --force    # re-run even if already completed
```

### `mbp audit`

Checks for drift between what mbp set up and the current state:

- **Homebrew** — missing packages from Brewfiles
- **mise** — runtimes not matching expected versions
- **Dotfiles** — symlinks broken or files modified since setup
- **macOS defaults** — settings that have changed since setup

```
$ mbp audit
  → Checking Homebrew...    ✓ all packages present
  → Checking mise...        ✓ all runtimes installed
  → Checking dotfiles...    ✗ ~/.gitconfig modified (SHA mismatch)
  → Checking macOS defaults... ✓ all settings match
  1 issue found.
```

### `mbp ssh`

Interactive SSH key manager — list existing keys, view public keys, or
create new ones with sensible defaults (Ed25519, Keychain persistence).

### `mbp tour`

An interactive walkthrough of everything that was installed. Press Enter
to advance through each section.

### `mbp status`

Shows the state of each module (ok, error, or not run) and when mbp last ran.

### `mbp update`

Pulls the latest version from GitHub and optionally re-runs setup for any
new or updated modules.

---

## How it works

### Interactive module selection

The first time you run `mbp setup`, a picker lets you choose which modules
to install. Uses [@clack/prompts](https://github.com/bombshell-dev/clack)
for a rich terminal UI when Node.js is available, falling back to plain
bash prompts on fresh Macs.

The selection is saved to `~/.mbp/selected_modules.txt` and later migrated
into `~/.mbp/state.json`.

### State tracking

mbp tracks which modules have run in `~/.mbp/state.json`. A completed
module is skipped on re-runs unless you pass `--force`.

```bash
MBP_FORCE=1 mbp setup --module mise   # re-run just mise
```

### Bootstrap problem

Modules 01-02 (Xcode, Homebrew) need to run before `jq` is available.
These modules use a plain-text fallback (`~/.mbp/state.txt`). Module 03
migrates the plain-text state to JSON automatically.

### Dotfile management

mbp symlinks dotfiles from the repo to `~`:

```
~/.zshrc           → <repo>/dotfiles/zshrc
~/.gitconfig       → <repo>/dotfiles/gitconfig
~/.ssh/config      → <repo>/dotfiles/ssh-config
~/.tool-versions   → <repo>/dotfiles/tool-versions
~/.vimrc           → <repo>/dotfiles/vimrc
```

Originals are backed up to `~/.mbp/backups/dotfiles-YYYYMMDD-HHMMSS/`
before symlinking. Personal overrides go in `~/.zshrc.local` (gitignored).

---

## Installing on a fresh Mac

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/devizerio/mbp/main/install.sh)
```

The install script:

1. Installs Xcode CLT if needed (git prerequisite)
2. Clones this repo to `~/.mbp/repo`
3. Adds `mbp` to your PATH via `~/.zprofile`
4. Installs Node.js dependencies for interactive prompts (if npm available)
5. Runs `mbp setup` (you choose which modules to install)

### Environment variables

```bash
MBP_REPO=~/code/mbp bash <(curl ...)    # clone to a custom path
MBP_BRANCH=dev bash <(curl ...)          # use a different branch
```

---

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac
- Internet connection

---

## Project structure

```
bin/mbp              — CLI entry point (subcommands: setup, audit, ssh, tour, update, status)
bin/mbp-prompts.mjs  — Node.js interactive prompts (@clack/prompts)
lib/
  core.sh            — logging, colors, idempotency helpers
  platform.sh        — macOS version and architecture detection
  state.sh           — state read/write (plain-text + JSON)
  audit.sh           — drift detection
modules/
  01-xcode.sh … 13-dev-dirs.sh
dotfiles/
  zshrc  gitconfig  ssh-config  tool-versions  vimrc
brewfiles/
  Brewfile.core      — essentials every machine needs
  Brewfile.dev       — developer tools (mise, bun, docker, VS Code, cloud CLIs)
  Brewfile.ai        — AI tooling (bundled if ai-tools module selected)
  Brewfile.apps      — desktop applications (bundled if apps module selected)
tour/
  steps.sh           — interactive walkthrough
  content/           — markdown content shown during the tour
install.sh           — bootstrap script for fresh Macs
```

---

## Inspired by

- [thoughtbot/laptop](https://github.com/thoughtbot/laptop) — the original
- [holman/dotfiles](https://github.com/holman/dotfiles)
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)

---

## Contributing

mbp is the internal Devizer provisioning tool, open-sourced to share what
we've found works well. Pull requests are welcome.

Run shellcheck before opening a PR:

```bash
shellcheck bin/mbp lib/*.sh modules/*.sh tour/steps.sh install.sh
```

---

## License

MIT. See [LICENSE](LICENSE).

---

*Built with ♥ by [Devizer](https://devizer.io)*
