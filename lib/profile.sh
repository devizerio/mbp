#!/usr/bin/env bash
# lib/profile.sh — Profile config parser
# Reads INI-style .conf files from profiles/ directory.
# Exports: MBP_PROFILE_MODULES, MBP_PROFILE_BREWFILES, MBP_PROFILE_MISE_TOOLS (space-separated)

profile_load() {
  local path="$1"

  if [ ! -f "$path" ]; then
    printf "profile not found: %s\n" "$path" >&2
    return 1
  fi

  # Defaults
  MBP_PROFILE_MODULES=""
  MBP_PROFILE_BREWFILES=""
  MBP_PROFILE_MISE_TOOLS=""
  local profile_format=0

  while IFS= read -r raw_line; do
    # Skip comments and blank lines
    local line; line=$(echo "$raw_line" | sed 's/#.*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$line" ] && continue

    # Split on first =
    local key; key=$(echo "$line" | cut -d= -f1 | sed 's/[[:space:]]*$//')
    local raw_val; raw_val=$(echo "$line" | cut -d= -f2- | sed 's/^[[:space:]]*//')

    case "$key" in
      format)
        profile_format="$raw_val"
        if [ "$profile_format" != "1" ]; then
          printf "profile: format version '%s' unknown, expected 1\n" "$profile_format" >&2
        fi
        ;;
      modules)
        # Split on commas, trim each value, validate names (alphanumeric + hyphens only)
        MBP_PROFILE_MODULES=$(echo "$raw_val" | tr ',' '\n' | \
          sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '\n' ' ' | sed 's/ $//')
        for _mod in $MBP_PROFILE_MODULES; do
          if ! echo "$_mod" | grep -qE '^[a-zA-Z0-9_-]+$'; then
            printf "profile: invalid module name '%s' — only alphanumeric, hyphens, underscores allowed\n" "$_mod" >&2
            return 1
          fi
        done
        ;;
      brewfiles)
        MBP_PROFILE_BREWFILES=$(echo "$raw_val" | tr ',' '\n' | \
          sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '\n' ' ' | sed 's/ $//')
        ;;
      mise_tools)
        MBP_PROFILE_MISE_TOOLS=$(echo "$raw_val" | tr ',' '\n' | \
          sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '\n' ' ' | sed 's/ $//')
        ;;
      *)
        printf "profile: unknown key '%s' — ignored\n" "$key"
        ;;
    esac
  done < "$path"

  export MBP_PROFILE_MODULES MBP_PROFILE_BREWFILES MBP_PROFILE_MISE_TOOLS
}

# Resolve a bare module name (e.g., "mise") to its script path (e.g., "modules/04-mise.sh")
# Usage: profile_resolve_module_path <name> <repo_dir>
profile_resolve_module_path() {
  local name="$1"
  local repo_dir="${2:-$(pwd)}"
  local modules_dir="$repo_dir/modules"

  # Glob for NN-name.sh
  local found=""
  for f in "$modules_dir"/[0-9][0-9]-"${name}".sh; do
    if [ -f "$f" ]; then
      found="$f"
      break
    fi
  done

  if [ -z "$found" ]; then
    printf "profile: module '%s' not found in %s\n" "$name" "$modules_dir" >&2
    return 1
  fi

  echo "$found"
}
