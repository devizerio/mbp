# SSH — key management

**Your SSH keys are managed by 1Password and ready to use.**

mbp configures SSH to use the 1Password SSH agent. Your private keys
live in your vault — they never touch disk in plaintext, and you
authenticate with Touch ID or your vault password.

## What was configured

  ~/.ssh/config is symlinked from the mbp dotfiles.

Key settings:

  AddKeysToAgent    — keys are offered to the agent automatically
  IdentityAgent     — points to the 1Password agent socket
  ServerAliveInterval 60 — keeps connections alive

## GitHub SSH

The default identity for GitHub is:

  ~/.ssh/developer_ed25519

This key should be in your 1Password vault and added to your GitHub
account under Settings > SSH and GPG keys.

## Test your connection

  ssh -T git@github.com

You should see: "Hi <username>! You've successfully authenticated..."

## Per-client SSH config

Add client-specific SSH entries to:

  ~/.ssh/config.d/<client>.conf

These are auto-included by the main config. Format:

  Host bastion.acme.com
      User ubuntu
      IdentityFile ~/.ssh/acme_ed25519

## Key permissions

SSH requires strict permissions on private key files.
mbp sets these automatically: chmod 600 on all private keys.

If SSH complains about key permissions:

  chmod 600 ~/.ssh/developer_ed25519
