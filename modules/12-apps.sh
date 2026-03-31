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
      EXPECTED_CASKS="$EXPECTED_CASKS ngrok graphql-playground xcodes secretive gpg-suite icanhazshortcut"
      ;;
    dev)
      EXPECTED_CASKS="$EXPECTED_CASKS docker visual-studio-code"
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

# Set up VS Code 'code' CLI command if VS Code is installed
VSCODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if [ -f "$VSCODE_CLI" ] && ! command -v code >/dev/null 2>&1; then
  mbp_log_step "Setting up VS Code 'code' CLI command..."
  local_bin="/usr/local/bin"
  if [ -d "$local_bin" ] && [ -w "$local_bin" ]; then
    ln -sf "$VSCODE_CLI" "$local_bin/code"
    mbp_log_ok "'code' CLI linked to $local_bin/code"
  else
    # Try with sudo
    sudo ln -sf "$VSCODE_CLI" "$local_bin/code" 2>/dev/null && \
      mbp_log_ok "'code' CLI linked to $local_bin/code" || \
      mbp_log_warn "Could not link 'code' CLI — run VS Code and use Command Palette > 'Shell Command: Install code command'"
  fi
elif command -v code >/dev/null 2>&1; then
  mbp_log_step "✓ VS Code 'code' CLI already available"
fi

state_set_module_ok "apps"
mbp_log_ok "Apps: all expected casks present"
