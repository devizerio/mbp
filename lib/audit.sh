#!/usr/bin/env bash
# lib/audit.sh — Drift detection for mbp audit subcommand
# Checks tracked configuration against current machine state.

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

AUDIT_ISSUES=0
AUDIT_CATEGORIES=0

# === Homebrew audit ===
audit_homebrew() {
  local repo_dir="$1"
  local brewfiles_dir="$repo_dir/brewfiles"
  local profile_brewfiles="${MBP_PROFILE_BREWFILES:-core dev}"

  printf "\n  ${MBP_COLOR_BOLD}Homebrew:${MBP_COLOR_RESET}\n"

  local category_issues=0
  for bf in $profile_brewfiles; do
    local bfpath="$brewfiles_dir/Brewfile.$bf"
    [ -f "$bfpath" ] || continue

    # brew bundle check returns non-zero if anything is missing
    local missing_output
    if ! missing_output=$(brew bundle check --file="$bfpath" --no-lock 2>&1); then
      # Parse missing packages from output
      echo "$missing_output" | grep "^The following" -A 999 | grep "^  " | \
        sed 's/^  //' | while IFS= read -r pkg; do
          printf "    ${MBP_COLOR_ERROR}✗${MBP_COLOR_RESET}  Missing: %s\n" "$pkg"
          category_issues=$((category_issues + 1))
        done
    fi
  done

  # Check for extra formulae (informational)
  local installed_count; installed_count=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
  printf "    ${MBP_COLOR_DIM}%s formulae installed${MBP_COLOR_RESET}\n" "$installed_count"

  if [ "$category_issues" -eq 0 ]; then
    printf "    ${MBP_COLOR_SUCCESS}✓${MBP_COLOR_RESET}  All tracked packages installed\n"
  else
    AUDIT_ISSUES=$((AUDIT_ISSUES + category_issues))
    AUDIT_CATEGORIES=$((AUDIT_CATEGORIES + 1))
  fi
}

# === mise audit ===
audit_mise() {
  printf "\n  ${MBP_COLOR_BOLD}mise:${MBP_COLOR_RESET}\n"

  if ! command -v mise >/dev/null 2>&1; then
    printf "    ${MBP_COLOR_ERROR}✗${MBP_COLOR_RESET}  mise not installed\n"
    AUDIT_ISSUES=$((AUDIT_ISSUES + 1))
    AUDIT_CATEGORIES=$((AUDIT_CATEGORIES + 1))
    return
  fi

  local tracked_tools="${MBP_PROFILE_MISE_TOOLS:-}"
  local category_issues=0

  for tool_spec in $tracked_tools; do
    local tool_name; tool_name=$(echo "$tool_spec" | cut -d@ -f1)
    local expected_version; expected_version=$(echo "$tool_spec" | cut -d@ -f2)

    local actual_version
    actual_version=$(mise list "$tool_name" 2>/dev/null | grep "(set)" | awk '{print $2}' | head -1)

    if [ -z "$actual_version" ]; then
      printf "    ${MBP_COLOR_ERROR}✗${MBP_COLOR_RESET}  %s: not installed (expected %s)\n" "$tool_name" "$expected_version"
      category_issues=$((category_issues + 1))
    elif [ "$expected_version" != "latest" ] && ! echo "$actual_version" | grep -q "^${expected_version}"; then
      printf "    ${MBP_COLOR_WARN}⚠${MBP_COLOR_RESET}  %s: found %s (expected %s)\n" "$tool_name" "$actual_version" "$expected_version"
      category_issues=$((category_issues + 1))
    else
      printf "    ${MBP_COLOR_SUCCESS}✓${MBP_COLOR_RESET}  %s %s\n" "$tool_name" "$actual_version"
    fi
  done

  if [ "$category_issues" -gt 0 ]; then
    AUDIT_ISSUES=$((AUDIT_ISSUES + category_issues))
    AUDIT_CATEGORIES=$((AUDIT_CATEGORIES + 1))
  fi
}

# === Dotfiles audit ===
audit_dotfiles() {
  local repo_dir="$1"
  local dotfiles_dir="$repo_dir/dotfiles"

  printf "\n  ${MBP_COLOR_BOLD}Dotfiles:${MBP_COLOR_RESET}\n"

  local -A DOTFILE_MAP=(
    ["zshrc"]=".zshrc"
    ["gitconfig"]=".gitconfig"
    ["ssh-config"]=".ssh/config"
    ["tool-versions"]=".tool-versions"
  )

  local category_issues=0

  for canonical in "${!DOTFILE_MAP[@]}"; do
    local installed_path="$HOME/${DOTFILE_MAP[$canonical]}"
    local canonical_path="$dotfiles_dir/$canonical"

    [ -f "$canonical_path" ] || continue

    if [ ! -e "$installed_path" ]; then
      printf "    ${MBP_COLOR_ERROR}✗${MBP_COLOR_RESET}  %s: not found\n" "${DOTFILE_MAP[$canonical]}"
      category_issues=$((category_issues + 1))
    elif [ -L "$installed_path" ]; then
      local target; target=$(readlink "$installed_path")
      if [ "$target" = "$canonical_path" ]; then
        printf "    ${MBP_COLOR_SUCCESS}✓${MBP_COLOR_RESET}  %s: linked (always in sync)\n" "${DOTFILE_MAP[$canonical]}"
      else
        printf "    ${MBP_COLOR_WARN}⚠${MBP_COLOR_RESET}  %s: symlink to wrong target\n" "${DOTFILE_MAP[$canonical]}"
        category_issues=$((category_issues + 1))
      fi
    else
      # Compare checksums
      local installed_sum; installed_sum=$(shasum -a 256 "$installed_path" | awk '{print $1}')
      local canonical_sum; canonical_sum=$(shasum -a 256 "$canonical_path" | awk '{print $1}')
      if [ "$installed_sum" = "$canonical_sum" ]; then
        printf "    ${MBP_COLOR_SUCCESS}✓${MBP_COLOR_RESET}  %s: matches canonical\n" "${DOTFILE_MAP[$canonical]}"
      else
        printf "    ${MBP_COLOR_ERROR}✗${MBP_COLOR_RESET}  %s: modified (diff below)\n" "${DOTFILE_MAP[$canonical]}"
        diff --color=always "$canonical_path" "$installed_path" 2>/dev/null | head -20 | \
          sed 's/^/      /'
        category_issues=$((category_issues + 1))
      fi
    fi
  done

  if [ "$category_issues" -gt 0 ]; then
    AUDIT_ISSUES=$((AUDIT_ISSUES + category_issues))
    AUDIT_CATEGORIES=$((AUDIT_CATEGORIES + 1))
  fi
}

# === macOS Defaults audit ===
# Parses tracked defaults from 11-macos-defaults.sh apply_default calls.
# Limited to scalar values (bool, int, float, string).
# ⚠ Some defaults may be reset by macOS updates — this is noted in output.
audit_macos_defaults() {
  local repo_dir="$1"
  local defaults_module="$repo_dir/modules/11-macos-defaults.sh"

  printf "\n  ${MBP_COLOR_BOLD}macOS Defaults:${MBP_COLOR_RESET}\n"
  printf "    ${MBP_COLOR_DIM}⚠ Some defaults may be reset by OS updates (expected)${MBP_COLOR_RESET}\n"

  if [ ! -f "$defaults_module" ]; then
    printf "    ${MBP_COLOR_WARN}⚠${MBP_COLOR_RESET}  module 11 not found — skipping defaults audit\n"
    return
  fi

  local category_issues=0

  # Parse apply_default lines: apply_default "domain" "key" "type" "value"
  while IFS= read -r line; do
    local domain key type expected_value
    # Extract quoted args using parameter expansion
    eval "set -- $(echo "$line" | sed 's/apply_default //')" 2>/dev/null || continue
    domain="$1" key="$2" type="$3" expected_value="$4"

    [ -z "$domain" ] || [ -z "$key" ] && continue

    local actual_value
    actual_value=$(defaults read "$domain" "$key" 2>/dev/null || echo "__MISSING__")

    # Normalize booleans from defaults read (0/1 -> false/true or vice versa)
    if [ "$type" = "bool" ]; then
      [ "$actual_value" = "0" ] && actual_value="false"
      [ "$actual_value" = "1" ] && actual_value="true"
    fi

    if [ "$actual_value" = "__MISSING__" ]; then
      printf "    ${MBP_COLOR_WARN}⚠${MBP_COLOR_RESET}  %s %s: not set (expected %s)\n" \
        "$domain" "$key" "$expected_value"
      category_issues=$((category_issues + 1))
    elif [ "$actual_value" != "$expected_value" ]; then
      printf "    ${MBP_COLOR_ERROR}✗${MBP_COLOR_RESET}  %s %s: expected %s, got %s\n" \
        "$domain" "$key" "$expected_value" "$actual_value"
      category_issues=$((category_issues + 1))
    else
      printf "    ${MBP_COLOR_SUCCESS}✓${MBP_COLOR_RESET}  %s %s = %s\n" "$domain" "$key" "$actual_value"
    fi
  done < <(grep "apply_default" "$defaults_module" | grep -v "^#" | grep -v "^[[:space:]]*#")

  if [ "$category_issues" -gt 0 ]; then
    AUDIT_ISSUES=$((AUDIT_ISSUES + category_issues))
    AUDIT_CATEGORIES=$((AUDIT_CATEGORIES + 1))
  fi
}

# === Summary ===
audit_summary() {
  printf "\n${MBP_COLOR_BOLD}─────────────────────────────────────${MBP_COLOR_RESET}\n"
  if [ "$AUDIT_ISSUES" -eq 0 ]; then
    printf "${MBP_COLOR_SUCCESS}✓ Clean — no drift detected${MBP_COLOR_RESET}\n\n"
    return 0
  else
    printf "${MBP_COLOR_WARN}%s %s found across %s %s.${MBP_COLOR_RESET}\n" \
      "$AUDIT_ISSUES" \
      "$([ "$AUDIT_ISSUES" -eq 1 ] && echo issue || echo issues)" \
      "$AUDIT_CATEGORIES" \
      "$([ "$AUDIT_CATEGORIES" -eq 1 ] && echo category || echo categories)"
    printf "Run ${MBP_COLOR_BRAND}mbp setup${MBP_COLOR_RESET} to fix tracked issues.\n\n"
    return 1
  fi
}
