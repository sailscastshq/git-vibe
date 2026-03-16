#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${GIT_VIBE_HOME:-$HOME/.git-vibe}"

rm -rf "${INSTALL_DIR}"

if [[ "$(git config --global --get core.hooksPath 2>/dev/null || true)" == "${INSTALL_DIR}/hooks" ]]; then
  git config --global --unset core.hooksPath || true
fi

echo "Git Vibe Flow removed from ${INSTALL_DIR}"
