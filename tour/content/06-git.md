# Git — version control

**Your git is configured and authenticated.**

mbp sets up git with sensible defaults and wires GitHub authentication
through the `gh` CLI so you never have to manage personal access tokens.

## What was configured

  ~/.gitconfig is symlinked from the mbp dotfiles.

Key settings:

  user.name         — Jensen Bernard
  user.email        — your Devizer email
  defaultBranch     — main
  push.autoSetup    — true (no more -u origin main)
  pull.rebase       — false (merge strategy)
  core.editor       — vim

## GitHub authentication

Credentials flow through the `gh` CLI:

  gh auth login     — authenticate (if not already done)
  gh auth status    — check current auth status

All git operations over HTTPS use gh automatically. No tokens in
your keychain or shell config.

## Per-client git identities

Each client environment has its own git identity. When you're inside
a client project directory, git uses the client-specific name and email
automatically via `includeIf "gitdir:..."`.

  mbp client add acme    — sets up identity for ~/Developer/Clients/acme/

## GPG signing

If a GPG key is found in your vault, commits are signed automatically.
Signed commits show a "Verified" badge on GitHub.

  git log --show-signature    — verify signatures on past commits

## Useful workflows

  git log --oneline -20       — recent commit history
  git diff main...HEAD        — changes on this branch
  gh pr create                — open a PR from the terminal
  gh pr status                — see PR status for current branch
