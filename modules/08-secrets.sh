#!/usr/bin/env bash
# Module 08: 1Password CLI — vault connection + key restoration
# Non-critical: failures are recorded but setup continues.

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

# Install 1Password CLI
if ! mbp_command_exists op; then
  mbp_log_step "Installing 1Password CLI..."
  brew install 1password-cli 2>/dev/null || {
    mbp_log_warn "Could not install via brew. Download from: https://1password.com/downloads/command-line/"
    state_set_module_error "secrets" "1" "1Password CLI not installed"
    exit 1
  }
fi

mbp_log_ok "1Password CLI: $(op --version 2>/dev/null)"

# Check authentication
if ! op account list 2>/dev/null | grep -q "."; then
  mbp_log_warn "1Password not authenticated."
  mbp_log_warn "Sign in: op signin"
  mbp_log_warn "Then re-run: mbp setup --module secrets --force"
  state_set_module_error "secrets" "1" "1Password CLI not authenticated"
  exit 1
fi

mbp_log_ok "1Password CLI authenticated"

# Restore GPG keys from vault (if not already present)
GPG_KEY_COUNT=$(gpg --list-secret-keys 2>/dev/null | grep -c "^sec" || echo 0)
if [ "${GPG_KEY_COUNT}" -eq 0 ]; then
  mbp_log_step "No GPG keys found locally."
  mbp_log_warn "To restore GPG keys, update the vault path in this module and re-run:"
  mbp_log_warn "  op read 'op://Personal/GPG Key/private key' | gpg --import"
fi

# Restore SSH keys from vault (if needed)
# Update the vault item paths to match your 1Password vault structure
mbp_log_step "SSH key restoration: update vault paths in modules/08-secrets.sh"
mbp_log_step "Example: op read 'op://Personal/developer_ed25519/private key' > ~/.ssh/developer_ed25519"

state_set_module_ok "secrets"
mbp_log_ok "Secrets: 1Password CLI ready"
