#!/usr/bin/env bash
# lib/core.sh — Shared functions: logging, colors, idempotency helpers
# Source this at the top of every module and lib file.

# === Color constants (ANSI 256-color) ===
# Respect NO_COLOR: https://no-color.org/
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  MBP_COLOR_BRAND="\033[38;5;26m"    # Blue-700 (#1D4ED8)
  MBP_COLOR_SUCCESS="\033[38;5;76m"  # Green
  MBP_COLOR_WARN="\033[38;5;214m"    # Amber
  MBP_COLOR_ERROR="\033[38;5;196m"   # Red
  MBP_COLOR_DIM="\033[38;5;245m"     # Gray
  MBP_COLOR_BOLD="\033[1m"
  MBP_COLOR_RESET="\033[0m"
else
  MBP_COLOR_BRAND=""
  MBP_COLOR_SUCCESS=""
  MBP_COLOR_WARN=""
  MBP_COLOR_ERROR=""
  MBP_COLOR_DIM=""
  MBP_COLOR_BOLD=""
  MBP_COLOR_RESET=""
fi

# === Module timing ===
MBP_MODULE_START_TIME=""

# === In-memory tracking (space-separated strings for subshell compat) ===
MBP_FAILED_MODULES="${MBP_FAILED_MODULES:-}"
MBP_SKIPPED_MODULES="${MBP_SKIPPED_MODULES:-}"

# === Logging functions ===
mbp_log_header() {
  local name="$1" n="$2" total="$3"
  MBP_MODULE_START_TIME=$(date +%s)
  printf "\n${MBP_COLOR_BRAND}${MBP_COLOR_BOLD}[%s/%s] %s${MBP_COLOR_RESET}\n" "$n" "$total" "$name"
}

mbp_log_ok() {
  printf "  ${MBP_COLOR_SUCCESS}✓${MBP_COLOR_RESET}  %s\n" "$1"
}

mbp_log_warn() {
  printf "  ${MBP_COLOR_WARN}⚠${MBP_COLOR_RESET}  %s\n" "$1"
}

mbp_log_error() {
  printf "  ${MBP_COLOR_ERROR}✗${MBP_COLOR_RESET}  %s\n" "$1" >&2
}

mbp_log_step() {
  printf "  ${MBP_COLOR_DIM}→${MBP_COLOR_RESET}  %s\n" "$1"
}

mbp_log_done() {
  local module_name="$1"
  local elapsed=0
  if [ -n "$MBP_MODULE_START_TIME" ]; then
    elapsed=$(( $(date +%s) - MBP_MODULE_START_TIME ))
  fi
  printf "  ${MBP_COLOR_SUCCESS}✓ %s — %ss${MBP_COLOR_RESET}\n" "$module_name" "$elapsed"
}

# === Idempotency helpers ===
mbp_command_exists() { command -v "$1" >/dev/null 2>&1; }
mbp_file_exists()    { [ -f "$1" ]; }
mbp_dir_exists()     { [ -d "$1" ]; }
mbp_symlink_exists() { [ -L "$1" ]; }

# === Brew helpers ===
mbp_brew_installed() { brew list --formula "$1" >/dev/null 2>&1; }
mbp_cask_installed() { brew list --cask "$1" >/dev/null 2>&1; }

# === Module runner (called by bin/mbp setup) ===
# Usage: mbp_run_module <module_path> <N> <total> [--force]
mbp_run_module() {
  local module_path="$1"
  local n="$2"
  local total="$3"
  local module_name
  module_name=$(basename "$module_path" .sh | sed 's/^[0-9]*-//')

  mbp_log_header "$module_name" "$n" "$total"

  # Check if should skip (state.sh provides this)
  # state_module_should_run returns 0 = run, 1 = skip
  if declare -f state_module_should_run >/dev/null 2>&1; then
    if ! state_module_should_run "$module_name"; then
      mbp_log_step "already done — skipping (use --force to re-run)"
      MBP_SKIPPED_MODULES="$MBP_SKIPPED_MODULES $module_name"
      return 0
    fi
  fi

  # Create log dir
  local log_dir="$HOME/.mbp/logs"
  mkdir -p "$log_dir"
  local log_file
  log_file="$log_dir/$(date +%Y%m%d)-${module_name}.log"

  # Run module in subshell, tee output to log file
  local exit_code=0
  bash "$module_path" 2>&1 | tee -a "$log_file" || exit_code=${PIPESTATUS[0]}

  if [ "$exit_code" -eq 0 ]; then
    mbp_log_done "$module_name"
  else
    mbp_log_error "$module_name failed (exit $exit_code) — log: $log_file"
    MBP_FAILED_MODULES="$MBP_FAILED_MODULES $module_name"

    # Critical modules: halt
    if [ "$module_name" = "xcode" ] || [ "$module_name" = "homebrew" ]; then
      mbp_log_error "Module '$module_name' is critical. Setup cannot continue."
      exit 1
    fi
  fi

  return "$exit_code"
}

# === ASCII logo ===
mbp_print_logo() {
  printf "${MBP_COLOR_BRAND}"
  cat << 'LOGO'
  ╔═══════════════════════════════════════╗
  ║   mbp — The Living Machine            ║
  ║   by Devizer                          ║
  ╚═══════════════════════════════════════╝
LOGO
  printf "${MBP_COLOR_RESET}\n"
}

# === Setup summary ===
mbp_print_summary() {
  local start_time="$1"
  local total_elapsed=$(( $(date +%s) - start_time ))

  printf "\n${MBP_COLOR_BOLD}─────────────────────────────────────${MBP_COLOR_RESET}\n"
  printf "${MBP_COLOR_BOLD}mbp setup complete — %ss${MBP_COLOR_RESET}\n\n" "$total_elapsed"

  if [ -n "$MBP_SKIPPED_MODULES" ]; then
    printf "${MBP_COLOR_DIM}Skipped (already ok): %s${MBP_COLOR_RESET}\n" "${MBP_SKIPPED_MODULES# }"
  fi

  if [ -n "$MBP_FAILED_MODULES" ]; then
    printf "${MBP_COLOR_WARN}Failed modules: %s${MBP_COLOR_RESET}\n" "${MBP_FAILED_MODULES# }"
    printf "${MBP_COLOR_WARN}Re-run failed modules: mbp setup --force${MBP_COLOR_RESET}\n"
  else
    printf "${MBP_COLOR_SUCCESS}All modules succeeded!${MBP_COLOR_RESET}\n"
    printf "\nNext: run ${MBP_COLOR_BRAND}mbp tour${MBP_COLOR_RESET} for a walkthrough of your new setup.\n"
  fi
  printf "\n"
}
