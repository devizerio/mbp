#!/usr/bin/env bash
# Module 06: Git configuration
# The canonical .gitconfig is managed via dotfiles module.
# This module sets machine-local values (GPG key, credential helper).

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

# GitHub credential helper via gh CLI
BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
GH_PATH="${BREW_PREFIX}/bin/gh"

if [ -f "$GH_PATH" ]; then
  if ! git config --global --get "credential.https://github.com.helper" 2>/dev/null | \
       grep -q "gh auth"; then
    git config --global credential."https://github.com".helper \
      "!${GH_PATH} auth git-credential"
    git config --global credential."https://gist.github.com".helper \
      "!${GH_PATH} auth git-credential"
    mbp_log_ok "GitHub credential helper configured"
  else
    mbp_log_ok "GitHub credential helper already configured"
  fi
else
  mbp_log_warn "gh CLI not found — skipping credential helper setup"
fi

# GPG signing: configure only if a key exists
# Module 08 (secrets) restores keys; this module picks them up if already present.
GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format SHORT 2>/dev/null | \
  grep "^sec" | awk '{print $2}' | cut -d/ -f2 | head -1)

if [ -n "$GPG_KEY_ID" ]; then
  git config --global user.signingkey "$GPG_KEY_ID"
  git config --global commit.gpgsign true
  mbp_log_ok "GPG signing enabled: $GPG_KEY_ID"
else
  mbp_log_warn "No GPG key found — run 'mbp setup --module secrets' to enable commit signing"
fi

state_set_module_ok "git"
mbp_log_ok "Git configured"
