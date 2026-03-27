#!/usr/bin/env bash
# Module 01: Xcode Command Line Tools
# CRITICAL — setup halts if this fails.
# Uses plain-text state (jq not yet available at this stage).

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

if xcode-select -p >/dev/null 2>&1; then
  mbp_log_ok "Xcode Command Line Tools already installed: $(xcode-select -p)"
  state_txt_set "xcode" "ok" "0"
  exit 0
fi

mbp_log_step "Installing Xcode Command Line Tools..."
xcode-select --install 2>/dev/null || true

# Wait for installation (polling, up to 30 minutes)
mbp_log_step "Waiting for Xcode CLT installation (complete the dialog if it appeared)..."
local_max=120  # 120 × 15s = 30 minutes
local_count=0
until xcode-select -p >/dev/null 2>&1; do
  sleep 15
  local_count=$((local_count + 1))
  if [ "$local_count" -ge "$local_max" ]; then
    mbp_log_error "Timed out waiting for Xcode CLT. Install manually and re-run mbp setup."
    state_txt_set "xcode" "error" "1"
    exit 1
  fi
done

# Accept license
sudo xcodebuild -license accept 2>/dev/null || true

mbp_log_ok "Xcode Command Line Tools installed: $(xcode-select -p)"
state_txt_set "xcode" "ok" "0"
