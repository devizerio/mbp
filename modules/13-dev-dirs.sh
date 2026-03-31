#!/usr/bin/env bash
# Module 13: mbp infrastructure directories
# Creates ~/.mbp runtime directories and ~/.local/bin.
# NEVER removes or overwrites existing directories.

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

DIRS=(
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
mbp_log_ok "Infrastructure directories ready"
