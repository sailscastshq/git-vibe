#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
REPO_DIR="${TMP_DIR}/demo"
WORKTREE_DIR="${TMP_DIR}/.vibe/demo/smoke-test"
WORKTREE_FINISH_DIR="${TMP_DIR}/.vibe/demo/worktree-finish"
INSTALL_HOME="${TMP_DIR}/home"
INSTALL_DIR="${TMP_DIR}/.git-vibe"
SHELL_REPO_DIR="${TMP_DIR}/shell-demo"
SHELL_WORKTREE_DIR="${TMP_DIR}/.vibe/shell-demo/shell-jump"
EXPECTED_SHELL_REPO_DIR=""
EXPECTED_SHELL_WORKTREE_DIR=""

cleanup() {
  rm -rf "${TMP_DIR}"
}

trap cleanup EXIT

fail() {
  printf 'smoke: %s\n' "$*" >&2
  exit 1
}

git init "${REPO_DIR}" >/dev/null
git -C "${REPO_DIR}" config user.name "Git Vibe Smoke"
git -C "${REPO_DIR}" config user.email "smoke@example.com"
git -C "${REPO_DIR}" switch -c main >/dev/null

printf '# Demo\n' > "${REPO_DIR}/README.md"
git -C "${REPO_DIR}" add README.md
VIBE_ALLOW_COMMIT_BASE=1 git -C "${REPO_DIR}" commit -m "chore: initial commit" >/dev/null
git -C "${REPO_DIR}" config vibe.baseBranch main
git -C "${REPO_DIR}" config vibe.branchPrefix feat/
git -C "${REPO_DIR}" config vibe.worktreeRoot ../.vibe

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" code smoke-test >/dev/null
)
[[ -d "${WORKTREE_DIR}" ]] || fail "worktree was not created"

printf '\nSmoke test change\n' >> "${WORKTREE_DIR}/README.md"
git -C "${WORKTREE_DIR}" add README.md
git -C "${WORKTREE_DIR}" commit -m "feat: update readme" >/dev/null

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" finish --local smoke-test >/dev/null
)

[[ ! -d "${WORKTREE_DIR}" ]] || fail "worktree still exists after finish"
if git -C "${REPO_DIR}" show-ref --verify --quiet refs/heads/feat/smoke-test; then
  fail "feature branch still exists after finish"
fi

printf 'smoke: ok\n'

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" code worktree-finish >/dev/null
)
[[ -d "${WORKTREE_FINISH_DIR}" ]] || fail "worktree finish path was not created"

printf '\nWorktree finish change\n' >> "${WORKTREE_FINISH_DIR}/README.md"
git -C "${WORKTREE_FINISH_DIR}" add README.md
git -C "${WORKTREE_FINISH_DIR}" commit -m "feat: update readme from worktree" >/dev/null

(
  cd "${WORKTREE_FINISH_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" finish --local >/dev/null
)

[[ ! -d "${WORKTREE_FINISH_DIR}" ]] || fail "worktree still exists after finishing from inside the vibe"
if git -C "${REPO_DIR}" show-ref --verify --quiet refs/heads/feat/worktree-finish; then
  fail "feature branch still exists after finishing from inside the vibe"
fi

printf 'smoke: worktree finish ok\n'

mkdir -p "${INSTALL_HOME}"

HOME="${INSTALL_HOME}" SHELL=/bin/bash GIT_VIBE_HOME="${INSTALL_DIR}" bash "${ROOT}/install.sh" >/dev/null

git init "${SHELL_REPO_DIR}" >/dev/null
git -C "${SHELL_REPO_DIR}" config user.name "Git Vibe Smoke"
git -C "${SHELL_REPO_DIR}" config user.email "smoke@example.com"
git -C "${SHELL_REPO_DIR}" switch -c main >/dev/null

printf '# Shell Demo\n' > "${SHELL_REPO_DIR}/README.md"
git -C "${SHELL_REPO_DIR}" add README.md
VIBE_ALLOW_COMMIT_BASE=1 git -C "${SHELL_REPO_DIR}" commit -m "chore: initial commit" >/dev/null
git -C "${SHELL_REPO_DIR}" config vibe.baseBranch main
git -C "${SHELL_REPO_DIR}" config vibe.branchPrefix feat/
git -C "${SHELL_REPO_DIR}" config vibe.worktreeRoot ../.vibe
EXPECTED_SHELL_REPO_DIR="$(cd "${SHELL_REPO_DIR}" && pwd -P)"

AUTO_CD_OUTPUT="$(HOME="${INSTALL_HOME}" SHELL=/bin/bash bash -lc '
  source ~/.bashrc
  cd "'"${SHELL_REPO_DIR}"'"
  git vibe code shell-jump >/dev/null
  pwd -P
')"

EXPECTED_SHELL_WORKTREE_DIR="$(cd "${SHELL_WORKTREE_DIR}" && pwd -P)"

[[ "${AUTO_CD_OUTPUT}" == "${EXPECTED_SHELL_WORKTREE_DIR}" ]] || fail "shell integration did not move into the new worktree"

FINISH_OUTPUT="$(HOME="${INSTALL_HOME}" SHELL=/bin/bash bash -lc '
  source ~/.bashrc
  cd "'"${SHELL_REPO_DIR}"'"
  git vibe finish --local shell-jump >/dev/null
  pwd -P
')"

[[ "${FINISH_OUTPUT}" == "${EXPECTED_SHELL_REPO_DIR}" ]] || fail "shell integration did not return to the base worktree after finish"

printf 'smoke: shell integration ok\n'
