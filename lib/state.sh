#!/usr/bin/env bash
# lib/state.sh — Machine state tracking
# Dual-mode: plain-text for modules 01-02 (jq not yet available),
# JSON via jq from module 03 onward.

MBP_STATE_DIR="${HOME}/.mbp"
MBP_STATE_JSON="${MBP_STATE_DIR}/state.json"
MBP_STATE_TXT="${MBP_STATE_DIR}/state.txt"
MBP_STATE_SCHEMA_VERSION=1

mkdir -p "$MBP_STATE_DIR"

# === Plain-text state (modules 01-02) ===
# Format: module=status:exit_code:timestamp

state_txt_set() {
  local module="$1" status="$2" exit_code="$3"
  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local line="${module}=${status}:${exit_code}:${ts}"
  local tmp="${MBP_STATE_TXT}.tmp"

  # Remove existing entry for this module, append new one
  if [ -f "$MBP_STATE_TXT" ]; then
    grep -v "^${module}=" "$MBP_STATE_TXT" > "$tmp" 2>/dev/null || true
  else
    touch "$tmp"
  fi
  echo "$line" >> "$tmp"
  mv "$tmp" "$MBP_STATE_TXT"
}

state_txt_get_status() {
  local module="$1"
  [ -f "$MBP_STATE_TXT" ] || return
  local line; line=$(grep "^${module}=" "$MBP_STATE_TXT" 2>/dev/null || true)
  [ -n "$line" ] && echo "$line" | cut -d= -f2 | cut -d: -f1
}

# === JSON state init ===
state_init_json() {
  local profile="${1:-devizer-full}"
  local mbp_version="${2:-1.0.0}"

  # Only create if not already present
  if [ -f "$MBP_STATE_JSON" ]; then
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    printf "state_init_json: jq not available\n" >&2
    return 1
  fi

  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  jq -n \
    --arg schema_version "$MBP_STATE_SCHEMA_VERSION" \
    --arg mbp_version "$mbp_version" \
    --arg profile "$profile" \
    --arg ts "$ts" \
    '{
      schema_version: ($schema_version | tonumber),
      mbp_version: $mbp_version,
      profile: $profile,
      last_run: $ts,
      modules: {}
    }' > "$MBP_STATE_JSON"
}

# === Migration: plain-text -> JSON ===
# Called at the start of module 03. Idempotent.
state_migrate_from_txt() {
  [ -f "$MBP_STATE_TXT" ] || return 0
  command -v jq >/dev/null 2>&1 || return 1

  # Initialize JSON if not yet present
  state_init_json

  local pkg_count="null"
  if [ -f "${MBP_STATE_DIR}/homebrew_package_count.tmp" ]; then
    pkg_count=$(cat "${MBP_STATE_DIR}/homebrew_package_count.tmp")
    rm -f "${MBP_STATE_DIR}/homebrew_package_count.tmp"
  fi

  # Migrate xcode and homebrew from plain-text to JSON
  while IFS= read -r line; do
    local module; module=$(echo "$line" | cut -d= -f1)
    local status; status=$(echo "$line" | cut -d= -f2 | cut -d: -f1)
    local exit_code; exit_code=$(echo "$line" | cut -d= -f2 | cut -d: -f2)
    local ts; ts=$(echo "$line" | cut -d= -f2 | cut -d: -f3-)

    local extra="{}"
    if [ "$module" = "homebrew" ] && [ "$pkg_count" != "null" ]; then
      extra=$(jq -n --argjson count "$pkg_count" '{"packages": $count}')
    fi

    local tmp; tmp=$(mktemp)
    jq --arg module "$module" \
       --arg status "$status" \
       --argjson exit_code "${exit_code:-0}" \
       --arg ts "$ts" \
       --argjson extra "$extra" \
       '.modules[$module] = ({status: $status, exit_code: $exit_code, ran_at: $ts} + $extra)' \
       "$MBP_STATE_JSON" > "$tmp" && mv "$tmp" "$MBP_STATE_JSON"
  done < "$MBP_STATE_TXT"

  # Rename plain-text file so migration only runs once
  mv "$MBP_STATE_TXT" "${MBP_STATE_TXT}.migrated"
}

# === JSON state operations ===
state_set_module_ok() {
  local module="$1"
  command -v jq >/dev/null 2>&1 || return 1
  [ -f "$MBP_STATE_JSON" ] || state_init_json
  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local tmp; tmp=$(mktemp)
  jq --arg module "$module" --arg ts "$ts" \
    '.modules[$module] = (.modules[$module] // {} | . + {status: "ok", exit_code: 0, ran_at: $ts})' \
    "$MBP_STATE_JSON" > "$tmp" && mv "$tmp" "$MBP_STATE_JSON"
}

state_set_module_error() {
  local module="$1" exit_code="${2:-1}" error_msg="${3:-unknown error}"
  command -v jq >/dev/null 2>&1 || return 1
  [ -f "$MBP_STATE_JSON" ] || state_init_json
  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local tmp; tmp=$(mktemp)
  jq --arg module "$module" --arg ts "$ts" \
     --argjson exit_code "$exit_code" --arg error "$error_msg" \
    '.modules[$module] = (.modules[$module] // {} | . + {status: "error", exit_code: $exit_code, ran_at: $ts, error: $error})' \
    "$MBP_STATE_JSON" > "$tmp" && mv "$tmp" "$MBP_STATE_JSON"
}

state_set_module_meta() {
  local module="$1" key="$2" value="$3"
  command -v jq >/dev/null 2>&1 || return 1
  [ -f "$MBP_STATE_JSON" ] || return 1
  local tmp; tmp=$(mktemp)
  # value may be a JSON fragment (array, number) or a plain string
  if echo "$value" | jq . >/dev/null 2>&1; then
    jq --arg module "$module" --arg key "$key" --argjson val "$value" \
      '.modules[$module][$key] = $val' \
      "$MBP_STATE_JSON" > "$tmp" && mv "$tmp" "$MBP_STATE_JSON"
  else
    jq --arg module "$module" --arg key "$key" --arg val "$value" \
      '.modules[$module][$key] = $val' \
      "$MBP_STATE_JSON" > "$tmp" && mv "$tmp" "$MBP_STATE_JSON"
  fi
}

state_get_module_status() {
  local module="$1"
  command -v jq >/dev/null 2>&1 || { state_txt_get_status "$module"; return; }
  [ -f "$MBP_STATE_JSON" ] || return
  jq -r --arg module "$module" '.modules[$module].status // empty' "$MBP_STATE_JSON" 2>/dev/null
}

state_get_profile() {
  command -v jq >/dev/null 2>&1 || return
  [ -f "$MBP_STATE_JSON" ] || return
  jq -r '.profile // empty' "$MBP_STATE_JSON" 2>/dev/null
}

state_set_profile() {
  local profile="$1"
  command -v jq >/dev/null 2>&1 || return 1
  [ -f "$MBP_STATE_JSON" ] || state_init_json "$profile"
  local tmp; tmp=$(mktemp)
  jq --arg profile "$profile" '.profile = $profile' "$MBP_STATE_JSON" > "$tmp" && mv "$tmp" "$MBP_STATE_JSON"
}

state_set_last_run() {
  command -v jq >/dev/null 2>&1 || return 1
  [ -f "$MBP_STATE_JSON" ] || return 1
  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local tmp; tmp=$(mktemp)
  jq --arg ts "$ts" '.last_run = $ts' "$MBP_STATE_JSON" > "$tmp" && mv "$tmp" "$MBP_STATE_JSON"
}

# === Idempotency decision ===
# Returns 0 = should run, 1 = should skip
state_module_should_run() {
  local module="$1"
  [ "${MBP_FORCE:-0}" = "1" ] && return 0

  local status
  if [ "$module" = "xcode" ] || [ "$module" = "homebrew" ]; then
    status=$(state_txt_get_status "$module")
    # Also check JSON if txt was migrated
    if [ -z "$status" ] && [ -f "$MBP_STATE_JSON" ]; then
      status=$(state_get_module_status "$module")
    fi
  else
    status=$(state_get_module_status "$module")
  fi

  [ "$status" = "ok" ] && return 1 || return 0
}

# === Schema check ===
state_check_schema() {
  command -v jq >/dev/null 2>&1 || return
  [ -f "$MBP_STATE_JSON" ] || return
  local current_schema
  current_schema=$(jq -r '.schema_version // 0' "$MBP_STATE_JSON" 2>/dev/null)
  if [ "$current_schema" -lt "$MBP_STATE_SCHEMA_VERSION" ] 2>/dev/null; then
    printf "state: schema v%s detected, expected v%s — migrating...\n" \
      "$current_schema" "$MBP_STATE_SCHEMA_VERSION"
    # Future migration functions go here
    local tmp; tmp=$(mktemp)
    jq --argjson v "$MBP_STATE_SCHEMA_VERSION" '.schema_version = $v' \
      "$MBP_STATE_JSON" > "$tmp" && mv "$tmp" "$MBP_STATE_JSON"
  fi
}
