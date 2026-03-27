#!/usr/bin/env bash
# Module 02: Homebrew + brew bundle
# CRITICAL — setup halts if this fails.
# Uses plain-text state (jq not yet available).

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/platform.sh"
source "$(dirname "$0")/../lib/state.sh"

BREWFILE_DIR="$(dirname "$0")/../brewfiles"

# Install Homebrew if missing
if ! mbp_command_exists brew; then
  mbp_log_step "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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

# Run brew bundle for each profile Brewfile
BREWFILES="${MBP_PROFILE_BREWFILES:-core dev}"
for bf in $BREWFILES; do
  BFPATH="$BREWFILE_DIR/Brewfile.$bf"
  if [ -f "$BFPATH" ]; then
    mbp_log_step "Bundling: Brewfile.$bf"
    brew bundle --file="$BFPATH" --no-lock --no-upgrade 2>&1 | \
      grep -v "^Using " | grep -v "^Homebrew Bundle complete" || true
  else
    mbp_log_warn "Brewfile.$bf not found, skipping"
  fi
done

# Record package count for state migration
PACKAGE_COUNT=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
mkdir -p "${HOME}/.mbp"
echo "$PACKAGE_COUNT" > "${HOME}/.mbp/homebrew_package_count.tmp"

state_txt_set "homebrew" "ok" "0"
mbp_log_ok "Homebrew: $PACKAGE_COUNT formulae installed"
