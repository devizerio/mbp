#!/usr/bin/env bash
# Module 02: Homebrew + brew bundle
# CRITICAL — setup halts if this fails.
# Uses plain-text state (jq not yet available).
set -o pipefail

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/platform.sh"
source "$(dirname "$0")/../lib/state.sh"

BREWFILE_DIR="$(dirname "$0")/../brewfiles"
SELECTED_MODULES_FILE="${HOME}/.mbp/selected_modules.txt"

# Install Homebrew if missing
if ! mbp_command_exists brew; then
  mbp_log_step "Installing Homebrew..."

  mkdir -p "${HOME}/.mbp/logs"
  local_log="${HOME}/.mbp/logs/$(date +%Y%m%d)-homebrew-install.log"

  if ! /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    2>&1 | tee -a "$local_log"; then
    mbp_log_error "Homebrew installation failed — see log: $local_log"
    state_txt_set "homebrew" "error" "1"
    return 1
  fi

  # Add brew to PATH for this shell session
  eval "$("$MBP_HOMEBREW_PREFIX/bin/brew" shellenv)"
  mbp_log_ok "Homebrew installed at $MBP_HOMEBREW_PREFIX"
else
  mbp_log_ok "Homebrew already installed: $(brew --version | head -1)"
fi

# Ensure brew is on PATH (for Apple Silicon after install)
if ! mbp_command_exists brew; then
  eval "$("$MBP_HOMEBREW_PREFIX/bin/brew" shellenv)"
fi

# Update Homebrew
mbp_log_step "Updating Homebrew..."
brew update --quiet 2>&1 | tail -3

# Determine which Brewfiles to bundle based on selected modules
BREWFILES="core dev"

if [ -f "$SELECTED_MODULES_FILE" ]; then
  if grep -qx "ai-tools" "$SELECTED_MODULES_FILE"; then
    BREWFILES="$BREWFILES ai"
  fi
  if grep -qx "apps" "$SELECTED_MODULES_FILE"; then
    BREWFILES="$BREWFILES apps"
  fi
else
  # No selection file — bundle all (default for re-runs after migration)
  BREWFILES="${MBP_PROFILE_BREWFILES:-core dev ai apps}"
fi

# Run brew bundle for each Brewfile
BUNDLE_FAILED=0
for bf in $BREWFILES; do
  BFPATH="$BREWFILE_DIR/Brewfile.$bf"
  if [ -f "$BFPATH" ]; then
    mbp_log_step "Bundling: Brewfile.$bf"
    if ! brew bundle --file="$BFPATH" --no-upgrade 2>&1; then
      mbp_log_warn "brew bundle failed for Brewfile.$bf — some packages may not have installed"
      BUNDLE_FAILED=1
    fi
  else
    mbp_log_warn "Brewfile.$bf not found, skipping"
  fi
done

if [ "$BUNDLE_FAILED" -eq 1 ]; then
  mbp_log_warn "Some brew packages failed to install — re-run mbp setup to retry"
fi

# Record package count for state migration
PACKAGE_COUNT=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
mkdir -p "${HOME}/.mbp"
echo "$PACKAGE_COUNT" > "${HOME}/.mbp/homebrew_package_count.tmp"

state_txt_set "homebrew" "ok" "0"
mbp_log_ok "Homebrew: $PACKAGE_COUNT formulae installed"
