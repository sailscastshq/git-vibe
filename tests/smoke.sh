#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
REPO_DIR="${TMP_DIR}/demo"
WORKTREE_DIR="${TMP_DIR}/.vibe/demo/smoke-test"

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
git -C "${REPO_DIR}" commit -m "chore: initial commit" >/dev/null
git -C "${REPO_DIR}" config vibe.baseBranch main
git -C "${REPO_DIR}" config vibe.branchPrefix feat/
git -C "${REPO_DIR}" config vibe.worktreeRoot ../.vibe

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" start smoke-test >/dev/null
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
