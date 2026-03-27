#!/usr/bin/env bash
# tour/steps.sh — Interactive post-setup walkthrough
# Steps are filtered to only show modules that were actually installed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MBP_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$MBP_REPO/lib/core.sh"
source "$MBP_REPO/lib/state.sh"

CONTENT_DIR="$SCRIPT_DIR/content"

# Map: "display_name:module_name:content_file"
ALL_STEPS=(
  "Homebrew:homebrew:01-homebrew.md"
  "mise — runtime version manager:mise:02-mise.md"
  "Claude Code — AI coding assistant:ai-tools:03-claude-code.md"
  "gstack — agent skills platform:ai-tools:04-gstack.md"
  "1Password CLI — secret management:secrets:05-1password-cli.md"
  "Git — version control:git:06-git.md"
  "SSH — key management:ssh:07-ssh.md"
  "Docker:docker:08-docker.md"
)

# Build active steps (only installed modules)
ACTIVE_STEPS=()
for step_def in "${ALL_STEPS[@]}"; do
  module_name="${step_def#*:}"
  module_name="${module_name%%:*}"
  status=$(state_get_module_status "$module_name" 2>/dev/null)
  if [ "$status" = "ok" ]; then
    ACTIVE_STEPS+=("$step_def")
  fi
done

TOTAL="${#ACTIVE_STEPS[@]}"

# === Welcome ===
clear
mbp_print_logo
printf "Welcome to your ${MBP_COLOR_BRAND}${MBP_COLOR_BOLD}Devizer MBP${MBP_COLOR_RESET}!\n"
printf "Let's walk through what was set up (%s tools).\n\n" "$TOTAL"
printf "Press ${MBP_COLOR_DIM}Enter${MBP_COLOR_RESET} to continue through each section.\n"
printf "\nPress Enter to start..."
read -r

N=0
for step_def in "${ACTIVE_STEPS[@]}"; do
  N=$((N + 1))
  display_name="${step_def%%:*}"
  rest="${step_def#*:}"
  module_name="${rest%%:*}"
  content_file="${rest##*:}"
  content_path="$CONTENT_DIR/$content_file"

  clear
  printf "${MBP_COLOR_BRAND}${MBP_COLOR_BOLD}[%s/%s] %s${MBP_COLOR_RESET}\n" "$N" "$TOTAL" "$display_name"
  printf "─────────────────────────────────────\n\n"

  if [ -f "$content_path" ]; then
    # Skip the H1 header line (already shown above), display rest
    tail -n +2 "$content_path"
  else
    printf "  ${MBP_COLOR_DIM}(content file not found: %s)${MBP_COLOR_RESET}\n" "$content_file"
  fi

  printf "\n"
  if [ "$N" -lt "$TOTAL" ]; then
    printf "${MBP_COLOR_DIM}[%s/%s] Press Enter to continue...${MBP_COLOR_RESET}" "$N" "$TOTAL"
  else
    printf "${MBP_COLOR_DIM}Press Enter to finish the tour...${MBP_COLOR_RESET}"
  fi
  read -r
done

# === Closing ===
clear
mbp_print_logo
printf "${MBP_COLOR_SUCCESS}${MBP_COLOR_BOLD}Tour complete!${MBP_COLOR_RESET}\n\n"
printf "Quick reference:\n\n"
printf "  ${MBP_COLOR_BRAND}mbp status${MBP_COLOR_RESET}           — see your current setup\n"
printf "  ${MBP_COLOR_BRAND}mbp audit${MBP_COLOR_RESET}            — check for config drift\n"
printf "  ${MBP_COLOR_BRAND}mbp update${MBP_COLOR_RESET}           — keep mbp current\n"
printf "  ${MBP_COLOR_BRAND}claude${MBP_COLOR_RESET}               — start Claude Code in any project\n"
printf "\n  Secrets and personal aliases: ${MBP_COLOR_DIM}~/.zshrc.local${MBP_COLOR_RESET}\n"
printf "\n"
