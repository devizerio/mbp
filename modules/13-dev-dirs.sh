#!/usr/bin/env bash
# Module 13: Developer directory structure
# Creates ~/Developer subdirectories and ~/.mbp runtime directories.
# NEVER removes or overwrites existing directories.

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

DEV="${HOME}/Developer"

# Standard Devizer project structure
DIRS=(
  "${DEV}/Clients"
  "${DEV}/agents"
  "${DEV}/ai"
  "${DEV}/playground"
  "${DEV}/Routine"
  "${HOME}/.mbp/backups"
  "${HOME}/.mbp/logs"
  "${HOME}/.local/bin"
)

for dir in "${DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    mbp_log_step "created: $dir"
  else
    mbp_log_step "exists:  $dir"
  fi
done

state_set_module_ok "dev-dirs"
mbp_log_ok "Developer directories ready"
