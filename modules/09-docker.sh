#!/usr/bin/env bash
# Module 09: Docker
# Detects existing Docker installation; installs via cask if missing.

source "$(dirname "$0")/../lib/core.sh"
source "$(dirname "$0")/../lib/state.sh"

if mbp_command_exists docker; then
  DOCKER_VER=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')
  mbp_log_ok "Docker already installed: v${DOCKER_VER}"
  state_set_module_ok "docker"
  exit 0
fi

# Docker Desktop should have been installed by Brewfile.dev
if mbp_cask_installed "docker"; then
  mbp_log_ok "Docker Desktop cask installed — open Docker.app to start the daemon"
else
  mbp_log_step "Installing Docker Desktop..."
  brew install --cask docker 2>&1 | tail -3
  mbp_log_ok "Docker Desktop installed — open Docker.app to start the daemon"
fi

state_set_module_ok "docker"
mbp_log_ok "Docker ready"
