#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(cd "$(mktemp -d)" && pwd -P)"
REPO_DIR="${TMP_DIR}/demo"
CONFIG_REPO_DIR="${TMP_DIR}/config-demo"
ORIGIN_DIR="${TMP_DIR}/origin.git"
CONFIG_GLOBAL_FILE="${TMP_DIR}/config-global.gitconfig"
HOOKS_DIR="${TMP_DIR}/hooks"
CONFIG_HOOK_LOG="${TMP_DIR}/config-hooks.log"
CONFIG_HOOK_RECORDER="${TMP_DIR}/record-vibe-hook.sh"
WORKTREE_DIR="${TMP_DIR}/.vibe/demo/smoke-test"
CONFIG_WORKTREE_DIR="${TMP_DIR}/repo-vibes/config-demo/repo-config-demo"
WORKTREE_FINISH_DIR="${TMP_DIR}/.vibe/demo/worktree-finish"
ISSUE_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/9-issue-aware-vibe-creation"
TITLE_ONLY_ISSUE_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/issue-title-only-branch"
SESSION_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/session-demo"
DOCTOR_DIRTY_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/doctor-dirty"
DOCTOR_STALE_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/doctor-stale"
REMOTE_DELETE_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/remote-delete"
REMOTE_ALREADY_GONE_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/remote-already-gone"
AUTO_EDITOR_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/auto-editor"
ALWAYS_EDITOR_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/always-editor"
NEVER_EDITOR_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/never-editor"
FORCED_EDITOR_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/forced-editor"
CODEX_AUTO_WORKTREE_DIR="${TMP_DIR}/.vibe/demo/codex-auto"
OPEN_WORKSPACE_DIR="${TMP_DIR}/.vibe/demo/open-workspace"
INSTALL_HOME="${TMP_DIR}/home"
INSTALL_DIR="${TMP_DIR}/.git-vibe"
SHELL_REPO_DIR="${TMP_DIR}/shell-demo"
SHELL_WORKTREE_DIR="${TMP_DIR}/.vibe/shell-demo/shell-jump"
FAKE_BIN_DIR="${TMP_DIR}/fake-bin"
CODE_LOG="${TMP_DIR}/code.log"
CODEX_LOG="${TMP_DIR}/codex.log"
ISSUE_9_TITLE_FILE="${TMP_DIR}/issue-9-title.txt"
ISSUE_10_TITLE_FILE="${TMP_DIR}/issue-10-title.txt"
PR_NUMBER_FILE="${TMP_DIR}/pr-number.txt"
PR_URL_FILE="${TMP_DIR}/pr-url.txt"
PR_TITLE_FILE="${TMP_DIR}/pr-title.txt"
PR_BODY_FILE="${TMP_DIR}/pr-body.txt"
PR_HEAD_FILE="${TMP_DIR}/pr-head.txt"
PR_BASE_FILE="${TMP_DIR}/pr-base.txt"
PR_DRAFT_FILE="${TMP_DIR}/pr-draft.txt"
EXPECTED_SHELL_REPO_DIR=""
EXPECTED_SHELL_WORKTREE_DIR=""
EXPECTED_WORKTREE_DIR=""
EXPECTED_CODEX_AUTO_WORKTREE_DIR=""
EXPECTED_VIBE_ROOT_DIR=""

cleanup() {
  rm -rf "${TMP_DIR}"
}

trap cleanup EXIT

fail() {
  printf 'smoke: %s\n' "$*" >&2
  exit 1
}

mkdir -p "${FAKE_BIN_DIR}"
cat > "${FAKE_BIN_DIR}/code" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "${CODE_LOG}"
EOF
chmod +x "${FAKE_BIN_DIR}/code"

cat > "${FAKE_BIN_DIR}/codex" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "${CODEX_LOG}"
EOF
chmod +x "${FAKE_BIN_DIR}/codex"

cat > "${CONFIG_HOOK_RECORDER}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

printf '%s|%s|%s|%s|%s\n' \
  "\${GIT_VIBE_HOOK:-}" \
  "\${GIT_VIBE_BRANCH:-}" \
  "\${GIT_VIBE_WORKTREE_PATH:-}" \
  "\${GIT_VIBE_VERSION:-}" \
  "\${GIT_VIBE_ISSUE_NUMBER:-}" >> "${CONFIG_HOOK_LOG}"

if [ "\${GIT_VIBE_HOOK:-}" = "post-create" ] && [ -n "\${GIT_VIBE_WORKTREE_PATH:-}" ]; then
  printf 'hooked\n' > "\${GIT_VIBE_WORKTREE_PATH}/.vibe-hook-created"
fi
EOF
chmod +x "${CONFIG_HOOK_RECORDER}"

cat > "${FAKE_BIN_DIR}/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

if [ "\${1:-}" = "issue" ] && [ "\${2:-}" = "view" ]; then
  number="\${3:-}"
  case "\${number}" in
    9)
      title="\$(<"${ISSUE_9_TITLE_FILE}")"
      ;;
    10)
      title="\$(<"${ISSUE_10_TITLE_FILE}")"
      ;;
    *)
      printf 'fake gh: unknown issue %s\n' "\${number}" >&2
      exit 1
      ;;
  esac

  printf '%s\t%s\t%s\n' "\${number}" "\${title}" "https://github.com/sailscastshq/git-vibe/issues/\${number}"
  exit 0
fi

if [ "\${1:-}" = "pr" ] && [ "\${2:-}" = "create" ]; then
  shift 2
  base=""
  head=""
  title=""
  body=""
  draft="false"

  while [ \$# -gt 0 ]; do
    case "\$1" in
      --base)
        base="\$2"
        shift 2
        ;;
      --head)
        head="\$2"
        shift 2
        ;;
      --title)
        title="\$2"
        shift 2
        ;;
      --body)
        body="\$2"
        shift 2
        ;;
      --draft)
        draft="true"
        shift
        ;;
      --web)
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  printf '%s\n' "\$base" > "${PR_BASE_FILE}"
  printf '%s\n' "\$head" > "${PR_HEAD_FILE}"
  printf '%s\n' "\$title" > "${PR_TITLE_FILE}"
  printf '%s\n' "\$body" > "${PR_BODY_FILE}"
  printf '%s\n' "\$draft" > "${PR_DRAFT_FILE}"
  printf '%s\n' "\$(<"${PR_URL_FILE}")"
  exit 0
fi

if [ "\${1:-}" = "pr" ] && [ "\${2:-}" = "view" ]; then
  target="\${3:-}"
  [ -f "${PR_HEAD_FILE}" ] || exit 1
  [ "\$target" = "\$(<"${PR_HEAD_FILE}")" ] || exit 1

  draft_state="ready"
  if [ "\$(<"${PR_DRAFT_FILE}")" = "true" ]; then
    draft_state="draft"
  fi

  printf '%s\t%s\t%s\tOPEN\t%s\tREVIEW_REQUIRED\n' \
    "\$(<"${PR_NUMBER_FILE}")" \
    "\$(<"${PR_TITLE_FILE}")" \
    "\$(<"${PR_URL_FILE}")" \
    "\$draft_state"
  exit 0
fi

if [ "\${1:-}" = "pr" ] && [ "\${2:-}" = "checks" ]; then
  target="\${3:-}"
  [ -f "${PR_HEAD_FILE}" ] || exit 1
  [ "\$target" = "\$(<"${PR_HEAD_FILE}")" ] || exit 1

  json_fields=""
  shift 3
  while [ \$# -gt 0 ]; do
    case "\$1" in
      --json)
        json_fields="\$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  if [ "\$json_fields" = "bucket" ]; then
    printf 'pass:1, pending:1\n'
    exit 0
  fi

  if [ "\$json_fields" = "bucket,state,name,link" ]; then
    printf 'pass\tsuccess\tunit\thttps://example.com/unit\n'
    printf 'pending\tpending\tlint\thttps://example.com/lint\n'
    exit 0
  fi

  exit 1
fi

printf 'fake gh: unsupported args: %s\n' "\$*" >&2
exit 1
EOF
chmod +x "${FAKE_BIN_DIR}/gh"

printf 'Issue aware vibe creation\n' > "${ISSUE_9_TITLE_FILE}"
printf 'Issue title only branch\n' > "${ISSUE_10_TITLE_FILE}"
printf '24\n' > "${PR_NUMBER_FILE}"
printf 'https://github.com/sailscastshq/git-vibe/pull/24\n' > "${PR_URL_FILE}"

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

git init "${CONFIG_REPO_DIR}" >/dev/null
git -C "${CONFIG_REPO_DIR}" config user.name "Git Vibe Smoke"
git -C "${CONFIG_REPO_DIR}" config user.email "smoke@example.com"
git -C "${CONFIG_REPO_DIR}" config core.hooksPath "${HOOKS_DIR}"
git -C "${CONFIG_REPO_DIR}" switch -c main >/dev/null

printf '# Config Demo\n' > "${CONFIG_REPO_DIR}/README.md"
printf '0.0.0\n' > "${CONFIG_REPO_DIR}/VERSION"
cat > "${CONFIG_REPO_DIR}/vibe.toml" <<EOF
[vibe]
worktreeRoot = "../repo-vibes"
openEditor = "never"
openWorkspaceWith = "vscode"
deleteRemoteOnFinish = true
issueBranchStyle = "number-only"
releaseVersionFile = "VERSION"

[hooks]
post-create = "${CONFIG_HOOK_RECORDER}"
pre-finish = "${CONFIG_HOOK_RECORDER}"
pre-release = "${CONFIG_HOOK_RECORDER}"
EOF
git -C "${CONFIG_REPO_DIR}" add README.md VERSION vibe.toml
VIBE_ALLOW_COMMIT_BASE=1 git -C "${CONFIG_REPO_DIR}" commit -m "chore: initial config demo" >/dev/null

git config --file "${CONFIG_GLOBAL_FILE}" vibe.worktreeRoot ../global-vibes
git config --file "${CONFIG_GLOBAL_FILE}" vibe.openEditor always
git config --file "${CONFIG_GLOBAL_FILE}" vibe.deleteRemoteOnFinish false

CONFIG_STATUS_OUTPUT="$(
  cd "${CONFIG_REPO_DIR}" >/dev/null
  GIT_CONFIG_GLOBAL="${CONFIG_GLOBAL_FILE}" "${ROOT}/bin/git-vibe" check
)"
[[ "${CONFIG_STATUS_OUTPUT}" == *"Repo config: ${CONFIG_REPO_DIR}/vibe.toml"* ]] || fail "check did not show the checked-in vibe.toml path"
[[ "${CONFIG_STATUS_OUTPUT}" == *"Vibe root: ${TMP_DIR}/repo-vibes/config-demo"* ]] || fail "repo vibe.toml should override the global worktree root"
[[ "${CONFIG_STATUS_OUTPUT}" == *"Open editor: never"* ]] || fail "repo vibe.toml should override the global openEditor setting"
[[ "${CONFIG_STATUS_OUTPUT}" == *"Delete remote on finish: true"* ]] || fail "repo vibe.toml should override the global deleteRemoteOnFinish setting"
[[ "${CONFIG_STATUS_OUTPUT}" == *"Hooks: post-create, pre-finish, pre-release"* ]] || fail "check did not summarize the configured lifecycle hooks"

git -C "${CONFIG_REPO_DIR}" config vibe.worktreeRoot ../local-vibes
git -C "${CONFIG_REPO_DIR}" config vibe.openEditor auto
git -C "${CONFIG_REPO_DIR}" config vibe.deleteRemoteOnFinish false

CONFIG_LOCAL_OVERRIDE_OUTPUT="$(
  cd "${CONFIG_REPO_DIR}" >/dev/null
  GIT_CONFIG_GLOBAL="${CONFIG_GLOBAL_FILE}" "${ROOT}/bin/git-vibe" check
)"
[[ "${CONFIG_LOCAL_OVERRIDE_OUTPUT}" == *"Vibe root: ${TMP_DIR}/local-vibes/config-demo"* ]] || fail "local git config should override the checked-in vibe.toml worktree root"
[[ "${CONFIG_LOCAL_OVERRIDE_OUTPUT}" == *"Open editor: auto"* ]] || fail "local git config should override the checked-in vibe.toml openEditor setting"
[[ "${CONFIG_LOCAL_OVERRIDE_OUTPUT}" == *"Delete remote on finish: false"* ]] || fail "local git config should override the checked-in vibe.toml deleteRemoteOnFinish setting"

git -C "${CONFIG_REPO_DIR}" config --unset vibe.worktreeRoot
git -C "${CONFIG_REPO_DIR}" config --unset vibe.openEditor
git -C "${CONFIG_REPO_DIR}" config --unset vibe.deleteRemoteOnFinish

: > "${CONFIG_HOOK_LOG}"

CONFIG_CODE_OUTPUT="$(
  cd "${CONFIG_REPO_DIR}" >/dev/null
  GIT_CONFIG_GLOBAL="${CONFIG_GLOBAL_FILE}" "${ROOT}/bin/git-vibe" code repo-config-demo
)"
[[ -d "${CONFIG_WORKTREE_DIR}" ]] || fail "repo vibe.toml did not create the expected worktree"
[[ -f "${CONFIG_WORKTREE_DIR}/.vibe-hook-created" ]] || fail "post-create hook did not run its setup task"
[[ "${CONFIG_CODE_OUTPUT}" == *"Hook: ran post-create"* ]] || fail "code did not report the post-create hook"
[[ "$(<"${CONFIG_HOOK_LOG}")" == *"post-create|feat/repo-config-demo|${CONFIG_WORKTREE_DIR}||"* ]] || fail "post-create hook did not receive the expected branch and worktree context"

CONFIG_REOPEN_OUTPUT="$(
  cd "${CONFIG_REPO_DIR}" >/dev/null
  GIT_CONFIG_GLOBAL="${CONFIG_GLOBAL_FILE}" "${ROOT}/bin/git-vibe" code repo-config-demo
)"
[[ "${CONFIG_REOPEN_OUTPUT}" == *"Opened feat/repo-config-demo"* ]] || fail "code did not reopen the existing config demo vibe"
[[ "$(grep -c '^post-create|' "${CONFIG_HOOK_LOG}")" == "1" ]] || fail "post-create hook should not rerun when reopening an existing vibe"

printf '\nConfig hook change\n' >> "${CONFIG_WORKTREE_DIR}/README.md"
git -C "${CONFIG_WORKTREE_DIR}" add README.md .vibe-hook-created
git -C "${CONFIG_WORKTREE_DIR}" commit -m "feat: update readme for config hook" >/dev/null

CONFIG_FINISH_OUTPUT="$(
  cd "${CONFIG_REPO_DIR}" >/dev/null
  GIT_CONFIG_GLOBAL="${CONFIG_GLOBAL_FILE}" "${ROOT}/bin/git-vibe" finish --local repo-config-demo
)"
[[ "${CONFIG_FINISH_OUTPUT}" == *"Hook: ran pre-finish"* ]] || fail "finish did not report the pre-finish hook"
[[ "$(<"${CONFIG_HOOK_LOG}")" == *"pre-finish|feat/repo-config-demo|${CONFIG_WORKTREE_DIR}||"* ]] || fail "pre-finish hook did not receive the expected branch and worktree context"
[[ ! -d "${CONFIG_WORKTREE_DIR}" ]] || fail "finish did not remove the config demo worktree"

CONFIG_RELEASE_OUTPUT="$(
  cd "${CONFIG_REPO_DIR}" >/dev/null
  GIT_CONFIG_GLOBAL="${CONFIG_GLOBAL_FILE}" "${ROOT}/bin/git-vibe" release 1.2.3
)"
[[ "${CONFIG_RELEASE_OUTPUT}" == *"Hook: ran pre-release"* ]] || fail "release did not report the pre-release hook"
[[ "$(<"${CONFIG_HOOK_LOG}")" == *"pre-release|main|${CONFIG_REPO_DIR}|1.2.3|"* ]] || fail "pre-release hook did not receive the expected release context"
[[ "$(<"${CONFIG_REPO_DIR}/VERSION")" == "1.2.3" ]] || fail "release did not honor vibe.toml releaseVersionFile"

printf 'smoke: repo config and hooks ok\n'

SMOKE_CODE_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" code smoke-test
)"
[[ -d "${WORKTREE_DIR}" ]] || fail "worktree was not created"
EXPECTED_WORKTREE_DIR="$(cd "${WORKTREE_DIR}" && pwd -P)"
EXPECTED_VIBE_ROOT_DIR="$(cd "${TMP_DIR}/.vibe" && pwd -P)/demo"
[[ "${SMOKE_CODE_OUTPUT}" == *"Compare: main...feat/smoke-test"* ]] || fail "code did not print the expected compare context"
[[ "${SMOKE_CODE_OUTPUT}" == *"Changes vs main: none"* ]] || fail "code did not print the expected clean summary"

printf '\nSmoke test change\n' >> "${WORKTREE_DIR}/README.md"
git -C "${WORKTREE_DIR}" add README.md

SMOKE_DIFF_OUTPUT="$(
  cd "${WORKTREE_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" diff
)"
[[ "${SMOKE_DIFF_OUTPUT}" == *"Smoke test change"* ]] || fail "diff did not include the current vibe changes"

SMOKE_CHECK_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" check smoke-test
)"
[[ "${SMOKE_CHECK_OUTPUT}" == *"Branch: feat/smoke-test"* ]] || fail "check did not show the vibe branch context"
[[ "${SMOKE_CHECK_OUTPUT}" == *"Compare: main...feat/smoke-test"* ]] || fail "check did not show the expected compare target"

SMOKE_CHECK_IN_VIBE_OUTPUT="$(
  cd "${WORKTREE_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" check
)"
[[ "${SMOKE_CHECK_IN_VIBE_OUTPUT}" != *"mkdir:"* ]] || fail "check printed a worktree root mkdir warning inside the vibe"
[[ "${SMOKE_CHECK_IN_VIBE_OUTPUT}" == *"Vibe root: ${EXPECTED_VIBE_ROOT_DIR}"* ]] || fail "check did not keep the shared vibe root when run inside the vibe"

SMOKE_ENTER_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" enter smoke-test --shell-output
)"
[[ "${SMOKE_ENTER_OUTPUT}" == *"Entering feat/smoke-test"* ]] || fail "enter did not announce the vibe it reopened"
[[ "${SMOKE_ENTER_OUTPUT}" == *"__GIT_VIBE_CHDIR__=${EXPECTED_WORKTREE_DIR}"* ]] || fail "enter did not emit the expected shell jump marker"

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

ISSUE_CODE_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" "${ROOT}/bin/git-vibe" code 9
)"

[[ -d "${ISSUE_WORKTREE_DIR}" ]] || fail "issue-aware code did not create the expected worktree"
[[ "${ISSUE_CODE_OUTPUT}" == *"Started feat/9-issue-aware-vibe-creation"* ]] || fail "issue-aware code did not create the expected branch"
[[ "${ISSUE_CODE_OUTPUT}" == *"Issue: #9 Issue aware vibe creation"* ]] || fail "issue-aware code did not print the issue context"
[[ "$(git -C "${REPO_DIR}" config --get vibe.issue.9.branch)" == "feat/9-issue-aware-vibe-creation" ]] || fail "issue-aware code did not remember the issue branch mapping"

printf 'Issue title changed later\n' > "${ISSUE_9_TITLE_FILE}"

ISSUE_REOPEN_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" "${ROOT}/bin/git-vibe" code 9
)"

[[ "${ISSUE_REOPEN_OUTPUT}" == *"Opened feat/9-issue-aware-vibe-creation"* ]] || fail "issue-aware code did not reopen the original branch after the issue title changed"
[[ "${ISSUE_REOPEN_OUTPUT}" == *"Issue: #9 Issue aware vibe creation"* ]] || fail "issue-aware reopen did not keep the original issue metadata"

ISSUE_CHECK_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" check 9
)"
[[ "${ISSUE_CHECK_OUTPUT}" == *"Branch: feat/9-issue-aware-vibe-creation"* ]] || fail "check did not resolve the issue number to the remembered branch"

printf '\nIssue change\n' >> "${ISSUE_WORKTREE_DIR}/README.md"
git -C "${ISSUE_WORKTREE_DIR}" add README.md
git -C "${ISSUE_WORKTREE_DIR}" commit -m "feat: update readme from issue vibe" >/dev/null

ISSUE_PR_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" "${ROOT}/bin/git-vibe" pr 9
)"
[[ "${ISSUE_PR_OUTPUT}" == *"Created PR for feat/9-issue-aware-vibe-creation"* ]] || fail "pr did not create a PR for the issue vibe"
[[ "$(cat "${PR_HEAD_FILE}")" == "feat/9-issue-aware-vibe-creation" ]] || fail "pr did not use the issue vibe branch as the PR head"
[[ "$(cat "${PR_BASE_FILE}")" == "main" ]] || fail "pr did not use the base branch"
[[ "$(cat "${PR_TITLE_FILE}")" == "Issue aware vibe creation" ]] || fail "pr did not use the issue title as the PR title"
[[ "$(<"${PR_BODY_FILE}")" == *"- update readme from issue vibe"* ]] || fail "pr did not summarize the recent commits in the PR body"
[[ "$(<"${PR_BODY_FILE}")" == *"Closes #9"* ]] || fail "pr did not link the issue in the PR body"
git --git-dir="${ORIGIN_DIR}" show-ref --verify --quiet refs/heads/feat/9-issue-aware-vibe-creation || fail "pr did not push the feature branch to origin"

ISSUE_PR_STATUS_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" "${ROOT}/bin/git-vibe" check 9
)"
[[ "${ISSUE_PR_STATUS_OUTPUT}" == *"PR: #24 Issue aware vibe creation"* ]] || fail "check did not show the linked PR"
[[ "${ISSUE_PR_STATUS_OUTPUT}" == *"Checks: pass:1, pending:1"* ]] || fail "check did not summarize the PR checks"

ISSUE_PR_CHECKS_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" "${ROOT}/bin/git-vibe" checks 9
)"
[[ "${ISSUE_PR_CHECKS_OUTPUT}" == *"Checks for feat/9-issue-aware-vibe-creation"* ]] || fail "checks did not target the issue vibe branch"
[[ "${ISSUE_PR_CHECKS_OUTPUT}" == *"unit"* ]] || fail "checks did not print the expected check rows"

git -C "${REPO_DIR}" config vibe.deleteRemoteOnFinish true

ISSUE_FINISH_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" finish --local 9
)"
[[ "${ISSUE_FINISH_OUTPUT}" == *"Remote branch: deleted origin/feat/9-issue-aware-vibe-creation"* ]] || fail "issue-aware finish did not delete the remote branch when vibe.deleteRemoteOnFinish=true"

[[ ! -d "${ISSUE_WORKTREE_DIR}" ]] || fail "issue-aware finish did not remove the worktree"
if git -C "${REPO_DIR}" show-ref --verify --quiet refs/heads/feat/9-issue-aware-vibe-creation; then
  fail "issue-aware finish did not delete the feature branch"
fi
if git --git-dir="${ORIGIN_DIR}" show-ref --verify --quiet refs/heads/feat/9-issue-aware-vibe-creation; then
  fail "issue-aware finish did not delete the remote branch"
fi

git -C "${REPO_DIR}" config vibe.issueBranchStyle title-only

ISSUE_COMMAND_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" "${ROOT}/bin/git-vibe" issue 10
)"

[[ -d "${TITLE_ONLY_ISSUE_WORKTREE_DIR}" ]] || fail "issue command did not create the title-only worktree"
[[ "${ISSUE_COMMAND_OUTPUT}" == *"Started feat/issue-title-only-branch"* ]] || fail "issue command did not honor vibe.issueBranchStyle=title-only"
[[ "$(git -C "${REPO_DIR}" config --get vibe.issue.10.branch)" == "feat/issue-title-only-branch" ]] || fail "issue command did not remember the title-only branch mapping"
git -C "${REPO_DIR}" worktree remove "${TITLE_ONLY_ISSUE_WORKTREE_DIR}" >/dev/null
git -C "${REPO_DIR}" branch -d feat/issue-title-only-branch >/dev/null
git -C "${REPO_DIR}" config --unset vibe.issueBranchStyle
git -C "${REPO_DIR}" config --unset vibe.deleteRemoteOnFinish

printf 'smoke: issue flow ok\n'

SESSION_CODE_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" code --agent codex --task "Fix login redirect" session-demo
)"
[[ -d "${SESSION_WORKTREE_DIR}" ]] || fail "session worktree was not created"
[[ "${SESSION_CODE_OUTPUT}" == *"Session: codex"* ]] || fail "code did not print the recorded session agent"
[[ "${SESSION_CODE_OUTPUT}" == *"Task: Fix login redirect"* ]] || fail "code did not print the recorded session task"
[[ "$(git -C "${REPO_DIR}" config --get vibe.session.session-demo.agent)" == "codex" ]] || fail "code did not store the session agent"
[[ "$(git -C "${REPO_DIR}" config --get vibe.session.session-demo.task)" == "Fix login redirect" ]] || fail "code did not store the session task"
[[ -n "$(git -C "${REPO_DIR}" config --get vibe.session.session-demo.updatedAt)" ]] || fail "code did not record session activity"

SESSION_LIST_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" list
)"
[[ "${SESSION_LIST_OUTPUT}" == *"SESSION"* ]] || fail "list did not print the session column"
[[ "${SESSION_LIST_OUTPUT}" == *"codex: Fix login redirect"* ]] || fail "list did not summarize the session metadata"

SESSION_STATUS_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" check session-demo
)"
[[ "${SESSION_STATUS_OUTPUT}" == *"Session: codex"* ]] || fail "check did not show the session agent"
[[ "${SESSION_STATUS_OUTPUT}" == *"Last activity:"* ]] || fail "check did not show session activity"

SESSION_UPDATE_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" session --task "Refine login redirect flow" session-demo
)"
[[ "${SESSION_UPDATE_OUTPUT}" == *"Updated session for feat/session-demo"* ]] || fail "session did not report the update"
[[ "${SESSION_UPDATE_OUTPUT}" == *"Task: Refine login redirect flow"* ]] || fail "session did not print the updated task"
[[ "$(git -C "${REPO_DIR}" config --get vibe.session.session-demo.task)" == "Refine login redirect flow" ]] || fail "session did not persist the updated task"

SESSION_SHOW_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" session session-demo
)"
[[ "${SESSION_SHOW_OUTPUT}" == *"Session for feat/session-demo:"* ]] || fail "session did not show the current metadata"
[[ "${SESSION_SHOW_OUTPUT}" == *"Task: Refine login redirect flow"* ]] || fail "session did not show the persisted task"

SESSION_ENTER_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" enter session-demo
)"
[[ "${SESSION_ENTER_OUTPUT}" == *"Session: codex"* ]] || fail "enter did not surface the session agent"
[[ "${SESSION_ENTER_OUTPUT}" == *"Task: Refine login redirect flow"* ]] || fail "enter did not surface the session task"

printf '\nSession change\n' >> "${SESSION_WORKTREE_DIR}/README.md"
git -C "${SESSION_WORKTREE_DIR}" add README.md
git -C "${SESSION_WORKTREE_DIR}" commit -m "feat: update readme from session vibe" >/dev/null

SESSION_FINISH_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" finish --local session-demo
)"
[[ "${SESSION_FINISH_OUTPUT}" == *"Finished feat/session-demo"* ]] || fail "finish did not close the session vibe"
[[ ! -d "${SESSION_WORKTREE_DIR}" ]] || fail "finish did not remove the session worktree"
if git -C "${REPO_DIR}" config --get vibe.session.session-demo.agent >/dev/null 2>&1; then
  fail "finish did not clear the session agent metadata"
fi
if git -C "${REPO_DIR}" config --get vibe.session.session-demo.task >/dev/null 2>&1; then
  fail "finish did not clear the session task metadata"
fi
if git -C "${REPO_DIR}" config --get vibe.session.session-demo.updatedAt >/dev/null 2>&1; then
  fail "finish did not clear the session activity metadata"
fi

printf 'smoke: session flow ok\n'

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" code remote-delete >/dev/null
)
[[ -d "${REMOTE_DELETE_WORKTREE_DIR}" ]] || fail "remote delete worktree was not created"
printf '\nRemote delete change\n' >> "${REMOTE_DELETE_WORKTREE_DIR}/README.md"
git -C "${REMOTE_DELETE_WORKTREE_DIR}" add README.md
git -C "${REMOTE_DELETE_WORKTREE_DIR}" commit -m "feat: update readme for remote delete" >/dev/null
git -C "${REMOTE_DELETE_WORKTREE_DIR}" push -u origin feat/remote-delete >/dev/null

REMOTE_DELETE_FINISH_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" finish --local --delete-remote remote-delete
)"
[[ "${REMOTE_DELETE_FINISH_OUTPUT}" == *"Remote branch: deleted origin/feat/remote-delete"* ]] || fail "finish --delete-remote did not report remote branch deletion"
if git --git-dir="${ORIGIN_DIR}" show-ref --verify --quiet refs/heads/feat/remote-delete; then
  fail "finish --delete-remote did not delete the remote branch"
fi

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" code remote-already-gone >/dev/null
)
[[ -d "${REMOTE_ALREADY_GONE_WORKTREE_DIR}" ]] || fail "remote already gone worktree was not created"
printf '\nRemote already gone change\n' >> "${REMOTE_ALREADY_GONE_WORKTREE_DIR}/README.md"
git -C "${REMOTE_ALREADY_GONE_WORKTREE_DIR}" add README.md
git -C "${REMOTE_ALREADY_GONE_WORKTREE_DIR}" commit -m "feat: update readme for remote already gone" >/dev/null
git -C "${REMOTE_ALREADY_GONE_WORKTREE_DIR}" push -u origin feat/remote-already-gone >/dev/null
git -C "${REMOTE_ALREADY_GONE_WORKTREE_DIR}" push origin --delete feat/remote-already-gone >/dev/null
git -C "${REPO_DIR}" config vibe.deleteRemoteOnFinish true

REMOTE_ALREADY_GONE_FINISH_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" finish --local remote-already-gone
)"
[[ "${REMOTE_ALREADY_GONE_FINISH_OUTPUT}" == *"Remote branch: already absent (origin/feat/remote-already-gone)"* ]] || fail "finish did not tolerate an already deleted remote branch"
git -C "${REPO_DIR}" config --unset vibe.deleteRemoteOnFinish

printf 'smoke: remote finish cleanup ok\n'

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" code doctor-dirty >/dev/null
)
[[ -d "${DOCTOR_DIRTY_WORKTREE_DIR}" ]] || fail "doctor dirty worktree was not created"

printf '\nDoctor dirty change\n' >> "${DOCTOR_DIRTY_WORKTREE_DIR}/README.md"

DOCTOR_LIST_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" list
)"
[[ "${DOCTOR_LIST_OUTPUT}" == *"STATE"* ]] || fail "list did not print the richer status header"
[[ "${DOCTOR_LIST_OUTPUT}" == *"feat/doctor-dirty"* ]] || fail "list did not include the doctor dirty vibe"
[[ "${DOCTOR_LIST_OUTPUT}" == *"dirty:1"* ]] || fail "list did not report the dirty vibe state"
[[ "${DOCTOR_LIST_OUTPUT}" == *"Doctor dirty change"* || "${DOCTOR_LIST_OUTPUT}" == *"1 file changed"* || "${DOCTOR_LIST_OUTPUT}" == *"1 insertion(+)"* ]] || fail "list did not summarize the dirty vibe changes"

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" code doctor-stale >/dev/null
)
[[ -d "${DOCTOR_STALE_WORKTREE_DIR}" ]] || fail "doctor stale worktree was not created"
rm -rf "${DOCTOR_STALE_WORKTREE_DIR}"

DOCTOR_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" doctor
)"
[[ "${DOCTOR_OUTPUT}" == *"Doctor findings:"* ]] || fail "doctor did not report stale worktree metadata"
[[ "${DOCTOR_OUTPUT}" == *"feat/doctor-stale"* ]] || fail "doctor did not identify the stale vibe branch"
[[ "${DOCTOR_OUTPUT}" == *"prunable"* || "${DOCTOR_OUTPUT}" == *"missing"* ]] || fail "doctor did not label the stale worktree state"

DOCTOR_REPAIR_OUTPUT="$(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" doctor --repair
)"
[[ "${DOCTOR_REPAIR_OUTPUT}" == *"Doctor: no remaining worktree problems"* ]] || fail "doctor --repair did not clear the stale worktree metadata"
if git -C "${REPO_DIR}" worktree list --porcelain | grep -q 'feat/doctor-stale'; then
  fail "doctor --repair did not prune the stale worktree entry"
fi

git -C "${REPO_DIR}" worktree remove --force "${DOCTOR_DIRTY_WORKTREE_DIR}" >/dev/null
git -C "${REPO_DIR}" branch -D feat/doctor-dirty >/dev/null
git -C "${REPO_DIR}" branch -D feat/doctor-stale >/dev/null

printf 'smoke: doctor flow ok\n'

git -C "${REPO_DIR}" config vibe.openEditor auto
: > "${CODE_LOG}"

(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" CODEX_SHELL=0 CODEX_INTERNAL_ORIGINATOR_OVERRIDE= "${ROOT}/bin/git-vibe" code auto-editor >/dev/null
)

[[ -d "${AUTO_EDITOR_WORKTREE_DIR}" ]] || fail "auto editor worktree was not created"
[[ ! -s "${CODE_LOG}" ]] || fail "auto editor mode should skip editor launch in non-interactive runs"
git -C "${REPO_DIR}" worktree remove "${AUTO_EDITOR_WORKTREE_DIR}" >/dev/null
git -C "${REPO_DIR}" branch -d feat/auto-editor >/dev/null

git -C "${REPO_DIR}" config vibe.openEditor always
: > "${CODE_LOG}"

(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" CODEX_SHELL=0 CODEX_INTERNAL_ORIGINATOR_OVERRIDE= "${ROOT}/bin/git-vibe" code always-editor >/dev/null
)

[[ -d "${ALWAYS_EDITOR_WORKTREE_DIR}" ]] || fail "always editor worktree was not created"
[[ -s "${CODE_LOG}" ]] || fail "always editor mode should launch the editor"
git -C "${REPO_DIR}" worktree remove "${ALWAYS_EDITOR_WORKTREE_DIR}" >/dev/null
git -C "${REPO_DIR}" branch -d feat/always-editor >/dev/null

git -C "${REPO_DIR}" config vibe.openEditor never
: > "${CODE_LOG}"

(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" CODEX_SHELL=0 CODEX_INTERNAL_ORIGINATOR_OVERRIDE= "${ROOT}/bin/git-vibe" code never-editor >/dev/null
)

[[ -d "${NEVER_EDITOR_WORKTREE_DIR}" ]] || fail "never editor worktree was not created"
[[ ! -s "${CODE_LOG}" ]] || fail "never editor mode should skip editor launch"
git -C "${REPO_DIR}" worktree remove "${NEVER_EDITOR_WORKTREE_DIR}" >/dev/null
git -C "${REPO_DIR}" branch -d feat/never-editor >/dev/null

: > "${CODE_LOG}"

(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" CODEX_SHELL=0 CODEX_INTERNAL_ORIGINATOR_OVERRIDE= "${ROOT}/bin/git-vibe" code --editor forced-editor >/dev/null
)

[[ -d "${FORCED_EDITOR_WORKTREE_DIR}" ]] || fail "forced editor worktree was not created"
[[ -s "${CODE_LOG}" ]] || fail "--editor should override vibe.openEditor=never"
git -C "${REPO_DIR}" worktree remove "${FORCED_EDITOR_WORKTREE_DIR}" >/dev/null
git -C "${REPO_DIR}" branch -d feat/forced-editor >/dev/null
git -C "${REPO_DIR}" config --unset vibe.openEditor

git -C "${REPO_DIR}" config vibe.openEditor always
git -C "${REPO_DIR}" config vibe.openWorkspaceWith auto
: > "${CODE_LOG}"
: > "${CODEX_LOG}"

(
  cd "${REPO_DIR}" >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" CODEX_SHELL=1 CODEX_INTERNAL_ORIGINATOR_OVERRIDE="Codex Desktop" "${ROOT}/bin/git-vibe" code codex-auto >/dev/null
)

[[ -d "${CODEX_AUTO_WORKTREE_DIR}" ]] || fail "codex auto worktree was not created"
EXPECTED_CODEX_AUTO_WORKTREE_DIR="$(cd "${CODEX_AUTO_WORKTREE_DIR}" && pwd -P)"
[[ ! -s "${CODE_LOG}" ]] || fail "auto workspace app should prefer Codex over VS Code in a Codex shell"
[[ "$(<"${CODEX_LOG}")" == *"app ${EXPECTED_CODEX_AUTO_WORKTREE_DIR}"* ]] || fail "auto workspace app did not launch Codex Desktop for the vibe"
git -C "${REPO_DIR}" worktree remove "${CODEX_AUTO_WORKTREE_DIR}" >/dev/null
git -C "${REPO_DIR}" branch -d feat/codex-auto >/dev/null

: > "${CODE_LOG}"
: > "${CODEX_LOG}"

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" code --no-editor open-workspace >/dev/null
  PATH="${FAKE_BIN_DIR}:$PATH" "${ROOT}/bin/git-vibe" open --vscode open-workspace >/dev/null
)

[[ -d "${OPEN_WORKSPACE_DIR}" ]] || fail "open workspace worktree was not created"
[[ -s "${CODE_LOG}" ]] || fail "open --vscode should launch VS Code"
[[ ! -s "${CODEX_LOG}" ]] || fail "open --vscode should not launch Codex"
git -C "${REPO_DIR}" worktree remove "${OPEN_WORKSPACE_DIR}" >/dev/null
git -C "${REPO_DIR}" branch -d feat/open-workspace >/dev/null
git -C "${REPO_DIR}" config --unset vibe.openWorkspaceWith
git -C "${REPO_DIR}" config --unset vibe.openEditor

printf 'smoke: editor modes ok\n'

(
  cd "${REPO_DIR}" >/dev/null
  "${ROOT}/bin/git-vibe" ship 0.1.0 --push >/dev/null
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

ENTER_OUTPUT="$(HOME="${INSTALL_HOME}" SHELL=/bin/bash bash -lc '
  source ~/.bashrc
  cd "'"${SHELL_REPO_DIR}"'"
  git vibe enter shell-jump >/dev/null
  pwd -P
')"

[[ "${ENTER_OUTPUT}" == "${EXPECTED_SHELL_WORKTREE_DIR}" ]] || fail "shell integration did not move into the existing worktree after enter"

FINISH_OUTPUT="$(HOME="${INSTALL_HOME}" SHELL=/bin/bash bash -lc '
  source ~/.bashrc
  cd "'"${SHELL_REPO_DIR}"'"
  git vibe finish --local shell-jump >/dev/null
  pwd -P
')"

[[ "${FINISH_OUTPUT}" == "${EXPECTED_SHELL_REPO_DIR}" ]] || fail "shell integration did not return to the base worktree after finish"

printf 'smoke: shell integration ok\n'
