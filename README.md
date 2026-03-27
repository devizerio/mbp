# mbp

**A MacBook Pro setup script for the modern developer.** Built by [Devizer](https://devizer.io).

One command takes a bare Mac from factory reset to fully provisioned — with
mise runtimes, AI tools, per-client isolation, and drift detection that keeps
everything honest.

```
bash <(curl -fsSL https://raw.githubusercontent.com/devizerio/mbp/main/install.sh)
```

---

## What it does

mbp runs 13 setup modules in sequence:

| # | Module | What it sets up |
|---|--------|----------------|
| 01 | xcode | Xcode Command Line Tools |
| 02 | homebrew | Homebrew + all packages from your profile |
| 03 | shell | Oh My Zsh, Homebrew zsh as default shell |
| 04 | mise | Runtime version manager (Node, Ruby, Python, …) |
| 05 | dotfiles | zshrc, gitconfig, ssh-config, vimrc (symlinked) |
| 06 | git | GitHub CLI credential helper, optional GPG signing |
| 07 | ssh | Key permissions, config.d include pattern |
| 08 | secrets | 1Password CLI |
| 09 | docker | Docker Desktop |
| 10 | ai-tools | Claude Code + gstack skills |
| 11 | macos-defaults | Dock, Finder, keyboard, screenshots |
| 12 | apps | Verify cask installations |
| 13 | dev-dirs | `~/Developer` structure, `~/.mbp` dirs |

Each module is **idempotent** — run `mbp setup` again at any time to install
what's missing and skip what's already done.

---

## Profiles

A profile is a `.conf` file that controls which modules run and which
packages install.

```
profiles/
  devizer-full.conf     — full Devizer stack
  client-minimal.conf   — stripped-down client machine
  personal.conf         — full stack + personal tools
```

Run a specific profile:

```bash
mbp setup --profile personal
```

---

## CLI reference

```
mbp setup [--profile NAME] [--module NAME] [--force]
mbp audit
mbp status
mbp tour
mbp update
mbp --version
mbp --help
```

### `mbp audit`

Checks for drift between what mbp set up and the current state:

- **Homebrew** — missing packages from Brewfiles
- **mise** — runtimes not matching profile versions
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

### `mbp tour`

An interactive walkthrough of everything that was installed — filtered to
your active profile. Press Enter to advance through each section.

```
$ mbp tour
```

---

## How it works

### State tracking

mbp tracks which modules have run in `~/.mbp/state.json`. A completed
module is skipped on re-runs unless you pass `--force`.

```bash
MBP_FORCE=1 mbp setup --module mise   # re-run just mise
```

The state file also records which client is active and when mbp last ran.

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

### Self-updating

```bash
mbp update
```

Pulls the latest version from GitHub and optionally re-runs setup for
any new modules. `state_check_schema` migrates the state file if the
schema version changed.

---

## Installing on a fresh Mac

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/devizerio/mbp/main/install.sh)
```

The install script:

1. Installs Xcode CLT if needed (git prerequisite)
2. Clones this repo to `~/.mbp/repo`
3. Adds `mbp` to your PATH via `~/.zprofile`
4. Runs `mbp setup --profile devizer-full`

### Environment variables

```bash
MBP_PROFILE=personal bash <(curl ...)   # use a different profile
MBP_REPO=~/code/mbp bash <(curl ...)    # clone to a custom path
```

---

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac
- Internet connection

---

## Project structure

```
bin/mbp              — CLI entry point
lib/
  core.sh            — logging, colors, idempotency helpers
  platform.sh        — macOS version and architecture detection
  state.sh           — state read/write (plain-text + JSON)
  profile.sh         — profile parser
  audit.sh           — drift detection
  client.sh          — client environment management
modules/
  01-xcode.sh … 13-dev-dirs.sh
dotfiles/
  zshrc  gitconfig  ssh-config  tool-versions  vimrc
profiles/
  devizer-full.conf  client-minimal.conf  personal.conf
brewfiles/
  Brewfile.core  Brewfile.dev  Brewfile.ai  Brewfile.apps  Brewfile.personal
tour/
  steps.sh
  content/  01-homebrew.md … 09-mbp-client.md
install.sh
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
