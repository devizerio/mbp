#!/usr/bin/env bash
# Module 10: AI tools — Claude Code, gstack
# Claude Code: installed via npm (requires node from module 04)
# gstack: installed at ~/.claude/skills/gstack/

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

# Ensure mise-managed node is on PATH
eval "$(mise activate bash 2>/dev/null)" || true
eval "$(mise env 2>/dev/null)" || true

# Ensure ~/.local/bin is on PATH
export PATH="${HOME}/.local/bin:${HOME}/.npm-global/bin:$PATH"

# === Claude Code ===
CLAUDE_PATH="${HOME}/.local/bin/claude"

if [ -f "$CLAUDE_PATH" ]; then
  CLAUDE_VER=$(claude --version 2>/dev/null | head -1 || echo "installed")
  mbp_log_ok "Claude Code already installed: $CLAUDE_VER"
else
  mbp_log_step "Installing Claude Code..."
  if mbp_command_exists npm; then
    npm install -g @anthropic-ai/claude-code 2>&1 | tail -3
    CLAUDE_VER=$(claude --version 2>/dev/null | head -1 || echo "installed")
    mbp_log_ok "Claude Code installed: $CLAUDE_VER"
  else
    mbp_log_warn "npm not found — install node (module 04) and re-run"
    state_set_module_error "ai-tools" "1" "npm not available for Claude Code install"
    exit 1
  fi
fi

# === gstack ===
GSTACK_SKILLS_DIR="${HOME}/.claude/skills/gstack"

if [ -d "$GSTACK_SKILLS_DIR" ]; then
  GSTACK_VER=$(cat "${GSTACK_SKILLS_DIR}/VERSION" 2>/dev/null || echo "installed")
  mbp_log_ok "gstack already installed: v$GSTACK_VER"
else
  mbp_log_step "Installing gstack..."
  mkdir -p "${HOME}/.claude/skills"
  git clone --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_SKILLS_DIR" 2>&1 | tail -3
  if [ -f "${GSTACK_SKILLS_DIR}/setup" ]; then
    cd "$GSTACK_SKILLS_DIR" && ./setup 2>&1 | tail -5
  fi
  GSTACK_VER=$(cat "${GSTACK_SKILLS_DIR}/VERSION" 2>/dev/null || echo "installed")
  mbp_log_ok "gstack installed: v$GSTACK_VER"
fi

CLAUDE_VER=$(claude --version 2>/dev/null | head -1 || echo "installed")
state_set_module_ok "ai-tools"
state_set_module_meta "ai-tools" "claude_version" "\"${CLAUDE_VER}\""

mbp_log_ok "AI tools: Claude Code ready, gstack ready"
