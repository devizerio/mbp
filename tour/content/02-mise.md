# mise — runtime version manager

**Install and switch between versions of Node, Ruby, Python, and more.**

mise is a modern replacement for asdf. It reads `.tool-versions` files and
automatically activates the right runtime for each project directory.

## What was installed

Your global runtimes (from `dotfiles/tool-versions`):

  nodejs   22.0.0
  ruby     3.3.0
  python   3.12.0

Your profile may add more — check `~/.tool-versions` or run `mise list`.

## Per-project versions

Drop a `.tool-versions` file in any project:

  nodejs 20.0.0
  ruby   3.2.0

mise activates these automatically when you `cd` into the directory.

## Useful commands

  mise list              — see all installed runtimes
  mise install           — install versions from .tool-versions
  mise use node@22       — set the global Node version
  mise exec -- node -v   — run a command with a specific runtime

## Client isolation

Each client environment (`mbp client add <name>`) gets its own
`.tool-versions` file, so different clients can run different runtimes
without conflict.

## Shell integration

mise is activated in your `.zshrc`:

  eval "$(mise activate zsh)"

This hooks into your shell so runtimes switch silently as you move
between directories.
