#!/usr/bin/env bash
# install.sh — Bootstrap mbp on a fresh Mac
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/devizerio/mbp/main/install.sh)
#
# Security note: This script is fetched over HTTPS from GitHub. It trusts:
#   - GitHub's TLS infrastructure for transport security
#   - The devizerio/mbp repository for code integrity
# For additional verification, download first and inspect:
#   curl -fsSL https://raw.githubusercontent.com/devizerio/mbp/main/install.sh -o install.sh
#   shasum -a 256 install.sh   # compare with published hash
#   bash install.sh
set -euo pipefail

MBP_REPO="${MBP_REPO:-$HOME/.mbp/repo}"
MBP_REMOTE="${MBP_REMOTE:-https://github.com/devizerio/mbp.git}"
MBP_BRANCH="${MBP_BRANCH:-main}"
MBP_PROFILE="${MBP_PROFILE:-devizer-full}"

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
  BOLD="\033[1m"
  RESET="\033[0m"
  BRAND="\033[38;5;26m"
  SUCCESS="\033[38;5;35m"
  DIM="\033[2m"
else
  BOLD="" RESET="" BRAND="" SUCCESS="" DIM=""
fi

# ── Logo ──────────────────────────────────────────────────────────────────────
print_logo() {
  printf "\n"
  printf "${BRAND}${BOLD}"
  printf "  ███╗   ███╗██████╗ ██████╗ \n"
  printf "  ████╗ ████║██╔══██╗██╔══██╗\n"
  printf "  ██╔████╔██║██████╔╝██████╔╝\n"
  printf "  ██║╚██╔╝██║██╔══██╗██╔═══╝ \n"
  printf "  ██║ ╚═╝ ██║██████╔╝██║     \n"
  printf "  ╚═╝     ╚═╝╚═════╝ ╚═╝     \n"
  printf "${RESET}\n"
  printf "  ${DIM}MacBook Pro setup by Devizer${RESET}\n\n"
}

# ── Helpers ───────────────────────────────────────────────────────────────────
log_step() { printf "  ${BRAND}→${RESET} %s\n" "$1"; }
log_ok()   { printf "  ${SUCCESS}✓${RESET} %s\n" "$1"; }
log_warn() { printf "  ⚠  %s\n" "$1"; }
die()      { printf "\n  ${BOLD}Error:${RESET} %s\n\n" "$1" >&2; exit 1; }

# ── Preflight ─────────────────────────────────────────────────────────────────
print_logo

# macOS check
if [ "$(uname -s)" != "Darwin" ]; then
  die "mbp only runs on macOS."
fi

# macOS version check (require 14+)
os_major=$(sw_vers -productVersion | cut -d. -f1)
if [ "$os_major" -lt 14 ]; then
  die "mbp requires macOS 14 (Sonoma) or later. Current: $(sw_vers -productVersion)"
fi

printf "  This script will:\n"
printf "    1. Clone mbp to ${DIM}$MBP_REPO${RESET}\n"
printf "    2. Add ${DIM}mbp${RESET} to your PATH\n"
printf "    3. Run ${DIM}mbp setup --profile $MBP_PROFILE${RESET}\n\n"
printf "  Profile:  ${BRAND}$MBP_PROFILE${RESET}\n"
printf "  Repo:     ${DIM}$MBP_REPO${RESET}\n\n"
printf "  ${DIM}Press Enter to continue, or Ctrl+C to cancel...${RESET}"
read -r

# ── Clone ─────────────────────────────────────────────────────────────────────
printf "\n"
log_step "Cloning mbp..."

if [ -d "$MBP_REPO/.git" ]; then
  log_ok "mbp repo already exists at $MBP_REPO — pulling latest"
  git -C "$MBP_REPO" pull --ff-only origin "$MBP_BRANCH" 2>/dev/null \
    || log_warn "Could not pull latest — proceeding with existing version"
else
  mkdir -p "$(dirname "$MBP_REPO")"
  # Xcode Command Line Tools needed for git — bootstrap if missing
  if ! command -v git &>/dev/null; then
    log_step "Installing Xcode Command Line Tools (this will take a few minutes)..."
    xcode-select --install 2>/dev/null || true
    printf "\n  ${DIM}Waiting for Xcode CLT installation...${RESET}\n"
    until xcode-select -p &>/dev/null; do sleep 5; done
    log_ok "Xcode CLT installed"
  fi
  git clone --branch "$MBP_BRANCH" --depth 1 "$MBP_REMOTE" "$MBP_REPO"
fi

log_ok "mbp cloned to $MBP_REPO"

# ── PATH bootstrap ────────────────────────────────────────────────────────────
MBP_BIN="$MBP_REPO/bin"

# Write a loader to .zprofile so mbp is available after install
LOADER_LINE="export PATH=\"$MBP_BIN:\$PATH\"  # mbp"
if [ -f "$HOME/.zprofile" ] && grep -qF "# mbp" "$HOME/.zprofile" 2>/dev/null; then
  log_ok "mbp already in .zprofile"
else
  printf "\n%s\n" "$LOADER_LINE" >> "$HOME/.zprofile"
  log_ok "Added mbp to ~/.zprofile"
fi

export PATH="$MBP_BIN:$PATH"

# ── Run setup ─────────────────────────────────────────────────────────────────
printf "\n"
log_step "Running mbp setup..."
printf "\n"

exec "$MBP_BIN/mbp" setup --profile "$MBP_PROFILE"
