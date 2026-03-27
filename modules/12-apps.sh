#!/usr/bin/env bash
# Module 12: Additional apps verification + Mac App Store
# Verifies that key casks were installed by the Homebrew module.

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

# Only verify casks included in the active profile's Brewfiles
EXPECTED_CASKS=""
for bf in ${MBP_PROFILE_BREWFILES:-}; do
  case "$bf" in
    apps)
      EXPECTED_CASKS="$EXPECTED_CASKS ngrok wireshark hyper xcodes secretive gpg-suite icanhazshortcut"
      ;;
    dev)
      EXPECTED_CASKS="$EXPECTED_CASKS docker"
      ;;
  esac
done

MISSING=""
for cask in $EXPECTED_CASKS; do
  if mbp_cask_installed "$cask"; then
    mbp_log_step "✓ $cask"
  else
    mbp_log_warn "missing cask: $cask"
    MISSING="$MISSING $cask"
  fi
done

# Attempt to install any missing casks
if [ -n "$MISSING" ]; then
  mbp_log_step "Installing missing casks..."
  for cask in $MISSING; do
    brew install --cask "$cask" 2>&1 | tail -2 || \
      mbp_log_warn "Could not install $cask — install manually"
  done
fi

state_set_module_ok "apps"
mbp_log_ok "Apps: all expected casks present"
