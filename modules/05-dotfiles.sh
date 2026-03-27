#!/usr/bin/env bash
# Module 05: Dotfiles — symlink canonical dotfiles to ~
# Backs up originals to ~/.mbp/backups/ before symlinking.
# NOTE: Any secrets in your current ~/.zshrc (e.g. API keys, env vars) must be
#       moved to ~/.zshrc.local BEFORE this module runs, as the canonical zshrc
#       will replace it. Backups are saved to ~/.mbp/backups/.

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

DOTFILES_DIR="$(dirname "$0")/../dotfiles"
DOTFILES_DIR="$(cd "$DOTFILES_DIR" && pwd)"
BACKUP_DIR="${HOME}/.mbp/backups/dotfiles-$(date +%Y%m%d-%H%M%S)"
LINKED=0
SKIPPED=0
WARNINGS=0

link_dotfile() {
  local src_name="$1"   # name in dotfiles/
  local dst_name="$2"   # destination relative to ~

  local src="${DOTFILES_DIR}/${src_name}"
  local dst="${HOME}/${dst_name}"

  if [ ! -f "$src" ]; then
    mbp_log_warn "dotfile not found in repo: $src_name — skipping"
    return
  fi

  # Already linked to our canonical file?
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    mbp_log_step "already linked: ~/${dst_name}"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  # Ensure parent directory exists
  mkdir -p "$(dirname "$dst")"

  # Backup existing regular file atomically (copy then link in one step)
  if [ -f "$dst" ] && [ ! -L "$dst" ]; then
    mkdir -p "$BACKUP_DIR"
    cp "$dst" "$BACKUP_DIR/$(basename "$dst")"
    mbp_log_step "backed up: ~/${dst_name} → $BACKUP_DIR"
  fi

  # Atomic symlink: create temp link then rename over destination
  local tmp_link
  tmp_link=$(mktemp "${dst}.mbp.XXXXXX")
  rm -f "$tmp_link"
  ln -s "$src" "$tmp_link"
  mv -f "$tmp_link" "$dst"
  mbp_log_ok "linked: ~/${dst_name}"
  LINKED=$((LINKED + 1))
}

# Warn about secrets in current .zshrc
if [ -f "${HOME}/.zshrc" ] && ! [ -L "${HOME}/.zshrc" ]; then
  if grep -q "export.*KEY\|export.*SECRET\|export.*PASSWORD\|export.*TOKEN" "${HOME}/.zshrc" 2>/dev/null; then
    mbp_log_warn "SECRET DETECTED in ~/.zshrc — move to ~/.zshrc.local before continuing"
    mbp_log_warn "Run: grep -E 'export.*KEY|SECRET|PASSWORD|TOKEN' ~/.zshrc"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# Symlink each dotfile
link_dotfile "zshrc"        ".zshrc"
link_dotfile "gitconfig"    ".gitconfig"
link_dotfile "ssh-config"   ".ssh/config"
link_dotfile "tool-versions" ".tool-versions"
link_dotfile "vimrc"        ".vimrc"

# Ensure .zshrc.local exists (for personal overrides)
if [ ! -f "${HOME}/.zshrc.local" ]; then
  cat > "${HOME}/.zshrc.local" << 'LOCALEOF'
# ~/.zshrc.local — Personal overrides not tracked by mbp
# This file is never symlinked or modified by mbp setup.
# Put here: client API keys, personal aliases, machine-specific PATH entries.

# Example:
# export STRIPE_KEY="sk_test_..."
# export DL_ENV_ENC_KEY="..."
# alias work="cd ~/Developer/Clients/myclient"
LOCALEOF
  mbp_log_ok "created ~/.zshrc.local (add your secrets/overrides here)"
fi

state_set_module_ok "dotfiles"
state_set_module_meta "dotfiles" "linked" "$LINKED"

if [ "$WARNINGS" -gt 0 ]; then
  mbp_log_warn "Dotfiles: $LINKED linked, $SKIPPED skipped — $WARNINGS warning(s), check above"
else
  mbp_log_ok "Dotfiles: $LINKED linked, $SKIPPED already current"
fi
