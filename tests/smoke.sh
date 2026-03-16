#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
REPO_DIR="${TMP_DIR}/demo"
ORIGIN_DIR="${TMP_DIR}/origin.git"
HOOKS_DIR="${TMP_DIR}/hooks"
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

mkdir -p "${HOOKS_DIR}"
for hook in pre-commit commit-msg pre-push; do
  cat > "${HOOKS_DIR}/${hook}" <<EOF
#!/usr/bin/env bash
exec "${ROOT}/bin/git-vibe" hook ${hook} "\$@"
EOF
  chmod +x "${HOOKS_DIR}/${hook}"
done

git init "${REPO_DIR}" >/dev/null
git -C "${REPO_DIR}" config user.name "Git Vibe Smoke"
git -C "${REPO_DIR}" config user.email "smoke@example.com"
git -C "${REPO_DIR}" config core.hooksPath "${HOOKS_DIR}"
git -C "${REPO_DIR}" switch -c main >/dev/null
git init --bare "${ORIGIN_DIR}" >/dev/null

printf '# Demo\n' > "${REPO_DIR}/README.md"
git -C "${REPO_DIR}" add README.md
VIBE_ALLOW_COMMIT_BASE=1 git -C "${REPO_DIR}" commit -m "chore: initial commit" >/dev/null
git -C "${REPO_DIR}" remote add origin "${ORIGIN_DIR}"
git -C "${REPO_DIR}" config vibe.baseBranch main
git -C "${REPO_DIR}" config vibe.branchPrefix feat/
git -C "${REPO_DIR}" config vibe.worktreeRoot ../.vibe
git -C "${REPO_DIR}" config vibe.disallowPushOnBase false
git -C "${REPO_DIR}" push -u origin main >/dev/null

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

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" release 0.1.0 --push >/dev/null
)

[[ "$(git -C "${REPO_DIR}" log -1 --pretty=%s)" == "chore(release): v0.1.0" ]] || fail "release did not create the expected commit"
[[ "$(git -C "${REPO_DIR}" tag --list "v0.1.0")" == "v0.1.0" ]] || fail "release did not create the expected tag"
[[ ! -f "${REPO_DIR}/VERSION" ]] || fail "release unexpectedly created VERSION"
git --git-dir="${ORIGIN_DIR}" show-ref --verify --quiet refs/tags/v0.1.0 || fail "release --push did not push the tag"
[[ "$(git -C "${REPO_DIR}" rev-parse HEAD)" == "$(git --git-dir="${ORIGIN_DIR}" rev-parse refs/heads/main)" ]] || fail "release --push did not push main"

printf 'smoke: release ok\n'

printf '0.1.0\n' > "${REPO_DIR}/VERSION"
git -C "${REPO_DIR}" add VERSION
VIBE_ALLOW_COMMIT_BASE=1 git -C "${REPO_DIR}" commit -m "chore: add version file" >/dev/null

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" release 0.2.0 --push >/dev/null
)

[[ "$(<"${REPO_DIR}/VERSION")" == "0.2.0" ]] || fail "release did not update VERSION"
[[ "$(git -C "${REPO_DIR}" log -1 --pretty=%s)" == "chore(release): v0.2.0" ]] || fail "release did not create the expected commit with VERSION present"
[[ "$(git -C "${REPO_DIR}" tag --list "v0.2.0")" == "v0.2.0" ]] || fail "release did not create the expected tag with VERSION present"
git --git-dir="${ORIGIN_DIR}" show-ref --verify --quiet refs/tags/v0.2.0 || fail "release --push did not push the second tag"
[[ "$(git -C "${REPO_DIR}" rev-parse HEAD)" == "$(git --git-dir="${ORIGIN_DIR}" rev-parse refs/heads/main)" ]] || fail "release --push did not push main after updating VERSION"

printf 'smoke: release with version file ok\n'

mkdir -p "${INSTALL_HOME}"

HOME="${INSTALL_HOME}" SHELL=/bin/bash GIT_VIBE_HOME="${INSTALL_DIR}" bash "${ROOT}/install.sh" >/dev/null

ALIAS_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/alias-shortcut"

(
  cd "${REPO_DIR}" >/dev/null
  HOME="${INSTALL_HOME}" git vc alias-shortcut >/dev/null
)
[[ -d "${ALIAS_WORKTREE_DIR}" ]] || fail "git vc did not create the expected worktree"
git -C "${REPO_DIR}" worktree remove "${ALIAS_WORKTREE_DIR}" >/dev/null
git -C "${REPO_DIR}" branch -d feat/alias-shortcut >/dev/null

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
  git vc shell-jump >/dev/null
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
