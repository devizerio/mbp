#!/usr/bin/env bash
# Module 07: SSH — fix permissions, generate config from discovered keys

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

SSH_DIR="${HOME}/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Fix permissions on all private keys
KEY_COUNT=0
for key in "$SSH_DIR"/*; do
  [ -f "$key" ] || continue
  # Skip public keys and known_hosts
  [[ "$key" == *.pub ]] && continue
  [[ "$(basename "$key")" == "known_hosts"* ]] && continue
  [[ "$(basename "$key")" == "authorized_keys" ]] && continue
  [[ "$(basename "$key")" == "config"* ]] && continue

  chmod 600 "$key"
  KEY_COUNT=$((KEY_COUNT + 1))
  mbp_log_step "permissions 600: $(basename "$key")"
done

# Ensure config.d directory for per-client/per-project includes
mkdir -p "${SSH_DIR}/config.d"

# Create ~/.ssh/config if not already symlinked by dotfiles module
if [ ! -f "${SSH_DIR}/config" ] && [ ! -L "${SSH_DIR}/config" ]; then
  mbp_log_step "No ~/.ssh/config found — dotfiles module will symlink it"
fi

mbp_log_ok "SSH: $KEY_COUNT keys secured"

state_set_module_ok "ssh"
mbp_log_ok "SSH configured"
