#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${GIT_VIBE_HOME:-$HOME/.git-vibe}"
BIN_DIR="${INSTALL_DIR}/bin"
HOOK_DIR="${INSTALL_DIR}/hooks"

mkdir -p "${BIN_DIR}" "${HOOK_DIR}"

cp "${ROOT}/bin/git-vibe" "${BIN_DIR}/git-vibe"
cp "${ROOT}/VERSION" "${INSTALL_DIR}/VERSION"
chmod +x "${BIN_DIR}/git-vibe"

for hook in pre-commit commit-msg pre-push; do
  cat > "${HOOK_DIR}/${hook}" <<EOF
#!/usr/bin/env bash
exec "${BIN_DIR}/git-vibe" hook ${hook} "\$@"
EOF
  chmod +x "${HOOK_DIR}/${hook}"
done

git config --global core.hooksPath "${HOOK_DIR}"
git config --global vibe.baseBranch main
git config --global vibe.branchPrefix feat/
git config --global vibe.worktreeRoot ../.vibe

cat <<EOF
Git Vibe Flow $(<"${ROOT}/VERSION") installed to ${INSTALL_DIR}

Global hooks path:
  ${HOOK_DIR}

Git config defaults:
  vibe.baseBranch=main
  vibe.branchPrefix=feat/
  vibe.worktreeRoot=../.vibe

Add this to your shell profile if ${BIN_DIR} is not already on PATH:
  export PATH="${BIN_DIR}:\$PATH"

After reloading your shell, run:
  git vibe version
EOF
