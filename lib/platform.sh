#!/usr/bin/env bash
# lib/platform.sh — Machine/OS detection
# Sets read-only variables describing the current platform.
# Source this early; it has no dependencies.

MBP_ARCH=$(uname -m)  # arm64 or x86_64

MBP_OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "0.0.0")
MBP_OS_MAJOR=$(echo "$MBP_OS_VERSION" | cut -d. -f1)

if [ "$MBP_ARCH" = "arm64" ]; then
  MBP_HOMEBREW_PREFIX="/opt/homebrew"
else
  MBP_HOMEBREW_PREFIX="/usr/local"
fi

# Validate macOS version
if [ "$MBP_OS_MAJOR" -lt 14 ] 2>/dev/null; then
  printf "mbp requires macOS 14 (Sonoma) or later. Detected: %s\n" "$MBP_OS_VERSION" >&2
  exit 1
fi

export MBP_ARCH MBP_OS_VERSION MBP_OS_MAJOR MBP_HOMEBREW_PREFIX
