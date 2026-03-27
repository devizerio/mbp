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

# SSH commit signing: uses the SSH key discovered by module 07
# No GPG or pinentry needed — 1Password handles key access seamlessly.
SSH_DIR="${HOME}/.ssh"
SSH_SIGNING_KEY=""

# Use the same key-discovery priority as module 07
for key in "$SSH_DIR"/*.pub; do
  [ -f "$key" ] || continue
  local_name="$(basename "$key" .pub)"
  if [ -z "$SSH_SIGNING_KEY" ]; then
    SSH_SIGNING_KEY="$key"
  fi
  case "$local_name" in
    developer_ed25519) SSH_SIGNING_KEY="$key" ;;
    id_ed25519)        [[ "$(basename "$SSH_SIGNING_KEY" .pub)" != "developer_ed25519" ]] && SSH_SIGNING_KEY="$key" ;;
    *ed25519*)         [[ "$(basename "$SSH_SIGNING_KEY" .pub)" != "developer_ed25519" && "$(basename "$SSH_SIGNING_KEY" .pub)" != "id_ed25519" ]] && SSH_SIGNING_KEY="$key" ;;
  esac
done

if [ -n "$SSH_SIGNING_KEY" ]; then
  git config --global gpg.format ssh
  git config --global user.signingkey "$SSH_SIGNING_KEY"
  git config --global commit.gpgsign true
  mbp_log_ok "SSH commit signing enabled: $(basename "$SSH_SIGNING_KEY")"
else
  mbp_log_warn "No SSH public key found — commit signing requires a key in ~/.ssh/"
fi

state_set_module_ok "git"
mbp_log_ok "Git configured"
