#!/usr/bin/env bash
# Module 04: mise — runtime version manager
# Replaces asdf. Migrates from asdf if present.

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

# Install mise via Homebrew if missing (listed in Brewfile.dev)
if ! mbp_command_exists mise; then
  mbp_log_step "Installing mise via Homebrew..."
  brew install mise
fi

# Activate mise for this shell session
eval "$(mise activate bash 2>/dev/null)" || true

# Trust global config
mise trust "${HOME}/.tool-versions" 2>/dev/null || true

# Migrate from asdf if installed and mise doesn't yet have global tools
if mbp_command_exists asdf && [ -f "${HOME}/.tool-versions" ]; then
  local_tools_count=$(mise list 2>/dev/null | wc -l | tr -d ' ')
  if [ "$local_tools_count" -lt 3 ]; then
    mbp_log_step "Detected asdf setup — importing .tool-versions into mise..."
    mise install 2>&1 | grep -v "^mise " | head -20 | while IFS= read -r line; do
      mbp_log_step "$line"
    done
  fi
fi

# Install / ensure profile tools
MISE_TOOLS="${MBP_PROFILE_MISE_TOOLS:-node@22 ruby@3.3 python@3.12 bun@latest}"
for tool_spec in $MISE_TOOLS; do
  tool_name="${tool_spec%%@*}"
  tool_version="${tool_spec#*@}"
  mbp_log_step "Ensuring ${tool_name}@${tool_version}..."
  if ! mise install "${tool_spec}" 2>&1 | grep -v "^mise " | tail -3 | while IFS= read -r line; do
    [ -n "$line" ] && mbp_log_step "$line"
  done; then
    mbp_log_warn "mise install ${tool_spec} may have failed"
  fi
  mise use --global "${tool_spec}" 2>/dev/null || true
done

INSTALLED=$(mise list --current 2>/dev/null | awk '{print $1"@"$2}' | tr '\n' ' ' | sed 's/ $//')
state_set_module_ok "mise"

state_set_module_meta "mise" "tools" \
  "[$(mise list --current 2>/dev/null | awk '{printf "\"%s@%s\",",$1,$2}' | sed 's/,$//')]"

mbp_log_ok "mise: $INSTALLED"
