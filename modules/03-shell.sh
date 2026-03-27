#!/usr/bin/env bash
# Module 03: Zsh + Oh My Zsh
# First module to use JSON state — triggers migration from plain-text at the top.

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

# === MIGRATION: plain-text -> JSON (runs once) ===
state_migrate_from_txt

# Install Oh My Zsh if not present
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
  mbp_log_step "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  mbp_log_ok "Oh My Zsh installed"
else
  mbp_log_ok "Oh My Zsh already installed"
fi

# Ensure Homebrew zsh is in /etc/shells
ZSH_BIN="$(brew --prefix 2>/dev/null)/bin/zsh"
if [ -f "$ZSH_BIN" ]; then
  if ! grep -qF "$ZSH_BIN" /etc/shells 2>/dev/null; then
    mbp_log_step "Adding Homebrew zsh to /etc/shells..."
    echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  fi

  # Change default shell if needed
  if [ "$SHELL" != "$ZSH_BIN" ]; then
    mbp_log_step "Setting Homebrew zsh as default shell..."
    chsh -s "$ZSH_BIN" 2>/dev/null || \
      mbp_log_warn "Could not change shell automatically. Run: chsh -s $ZSH_BIN"
  fi
fi

state_set_module_ok "shell"
mbp_log_ok "Shell: zsh $(zsh --version 2>/dev/null | awk '{print $2}') + Oh My Zsh"
