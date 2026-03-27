#!/usr/bin/env bash
# Module 11: macOS system defaults
# Every apply_default call is tracked by lib/audit.sh for drift detection.
# Scalar values only (bool, int, float, string).

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

# Helper: set a default only if not already at expected value
apply_default() {
  local domain="$1" key="$2" type="$3" value="$4"
  local current
  current=$(defaults read "$domain" "$key" 2>/dev/null || echo "__MISSING__")

  # Normalize booleans
  if [ "$type" = "bool" ]; then
    [ "$current" = "1" ] && current="true"
    [ "$current" = "0" ] && current="false"
  fi

  if [ "$current" = "$value" ]; then
    return 0  # Already set
  fi

  defaults write "$domain" "$key" "-${type}" "$value"
}

mbp_log_step "Dock..."
apply_default "com.apple.dock" "autohide"                  "bool"  "true"
apply_default "com.apple.dock" "autohide-delay"            "float" "0"
apply_default "com.apple.dock" "autohide-time-modifier"    "float" "0.3"
apply_default "com.apple.dock" "tilesize"                  "int"   "48"
apply_default "com.apple.dock" "show-recents"              "bool"  "false"
apply_default "com.apple.dock" "minimize-to-application"   "bool"  "true"
apply_default "com.apple.dock" "launchanim"                "bool"  "false"

mbp_log_step "Finder..."
apply_default "com.apple.finder" "AppleShowAllExtensions"  "bool"   "true"
apply_default "com.apple.finder" "ShowStatusBar"           "bool"   "true"
apply_default "com.apple.finder" "ShowPathbar"             "bool"   "true"
apply_default "com.apple.finder" "FXPreferredViewStyle"    "string" "Nlsv"
apply_default "com.apple.finder" "FXDefaultSearchScope"    "string" "SCcf"
apply_default "com.apple.finder" "FXEnableExtensionChangeWarning" "bool" "false"
apply_default "com.apple.finder" "_FXShowPosixPathInTitle" "bool"   "true"
apply_default "com.apple.finder" "NewWindowTarget"         "string" "PfHm"

mbp_log_step "Keyboard..."
apply_default "NSGlobalDomain" "KeyRepeat"        "int" "2"
apply_default "NSGlobalDomain" "InitialKeyRepeat" "int" "15"
apply_default "NSGlobalDomain" "ApplePressAndHoldEnabled" "bool" "false"

mbp_log_step "Trackpad..."
apply_default "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Clicking" "bool" "true"
apply_default "NSGlobalDomain" "com.apple.swipescrolldirection" "bool" "true"

mbp_log_step "Screenshots..."
mkdir -p "${HOME}/Desktop/Screenshots"
apply_default "com.apple.screencapture" "location" "string" "${HOME}/Desktop/Screenshots"
apply_default "com.apple.screencapture" "type"     "string" "png"
apply_default "com.apple.screencapture" "disable-shadow" "bool" "true"

mbp_log_step "General..."
apply_default "NSGlobalDomain" "AppleInterfaceStyle"           "string" "Dark"
apply_default "NSGlobalDomain" "AppleShowScrollBars"           "string" "WhenScrolling"
apply_default "NSGlobalDomain" "NSNavPanelExpandedStateForSaveMode" "bool" "true"
apply_default "NSGlobalDomain" "PMPrintingExpandedStateForPrint"    "bool" "true"
apply_default "NSGlobalDomain" "NSDocumentSaveNewDocumentsToCloud"  "bool" "false"

mbp_log_step "TextEdit..."
apply_default "com.apple.TextEdit" "RichText"        "int"    "0"
apply_default "com.apple.TextEdit" "PlainTextEncoding" "int"  "4"

mbp_log_step "Activity Monitor..."
apply_default "com.apple.ActivityMonitor" "OpenMainWindow" "bool" "true"
apply_default "com.apple.ActivityMonitor" "ShowCategory"   "int"  "0"

mbp_log_step "Security..."
# Enable macOS firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on 2>/dev/null || true
# Require password immediately after sleep/screen saver
apply_default "com.apple.screensaver" "askForPassword"      "int" "1"
apply_default "com.apple.screensaver" "askForPasswordDelay"  "int" "0"

# Restart affected system processes
mbp_log_step "Restarting system services..."
killall Dock    2>/dev/null || true
killall Finder  2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

state_set_module_ok "macos-defaults"
mbp_log_ok "macOS defaults applied"
