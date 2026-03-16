#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${GIT_VIBE_HOME:-$HOME/.git-vibe}"
BIN_DIR="${INSTALL_DIR}/bin"
HOOK_DIR="${INSTALL_DIR}/hooks"
REF="${GIT_VIBE_REF:-main}"
REPO_SLUG="${GIT_VIBE_REPO:-sailscastshq/git-vibe}"
RAW_BASE="https://raw.githubusercontent.com/${REPO_SLUG}/${REF}"
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd 2>/dev/null || pwd)"
PATH_LINE="export PATH=\"${BIN_DIR}:\$PATH\""
PATH_MARKER_BEGIN="# >>> git-vibe >>>"
PATH_MARKER_END="# <<< git-vibe <<<"

download() {
  local remote_path target
  remote_path="$1"
  target="$2"
  curl -fsSL "${RAW_BASE}/${remote_path}" -o "${target}"
}

detect_profile() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"

  case "${shell_name}" in
    zsh)
      printf '%s\n' "${HOME}/.zshrc"
      ;;
    bash)
      if [[ -f "${HOME}/.bashrc" || ! -f "${HOME}/.bash_profile" ]]; then
        printf '%s\n' "${HOME}/.bashrc"
      else
        printf '%s\n' "${HOME}/.bash_profile"
      fi
      ;;
    *)
      printf '%s\n' "${HOME}/.profile"
      ;;
  esac
}

ensure_path_in_profile() {
  local profile
  profile="$(detect_profile)"
  touch "${profile}"

  if grep -Fq "${PATH_MARKER_BEGIN}" "${profile}"; then
    printf '%s\n' "${profile}"
    return 0
  fi

  {
    printf '\n%s\n' "${PATH_MARKER_BEGIN}"
    printf '%s\n' "${PATH_LINE}"
    printf '%s\n' "${PATH_MARKER_END}"
  } >> "${profile}"

  printf '%s\n' "${profile}"
}

mkdir -p "${BIN_DIR}" "${HOOK_DIR}"

if [[ -f "${SCRIPT_DIR}/bin/git-vibe" && -f "${SCRIPT_DIR}/VERSION" ]]; then
  cp "${SCRIPT_DIR}/bin/git-vibe" "${BIN_DIR}/git-vibe"
  cp "${SCRIPT_DIR}/VERSION" "${INSTALL_DIR}/VERSION"
else
  download "bin/git-vibe" "${BIN_DIR}/git-vibe"
  download "VERSION" "${INSTALL_DIR}/VERSION"
fi

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
git config --global alias.vibe "!${BIN_DIR}/git-vibe"

PROFILE_FILE="$(ensure_path_in_profile)"

cat <<EOF
Git Vibe Flow $(<"${INSTALL_DIR}/VERSION") installed to ${INSTALL_DIR}

Global hooks path:
  ${HOOK_DIR}

Git alias:
  git vibe -> ${BIN_DIR}/git-vibe

Git config defaults:
  vibe.baseBranch=main
  vibe.branchPrefix=feat/
  vibe.worktreeRoot=../.vibe

Shell profile updated:
  ${PROFILE_FILE}

Current terminal note:
  The installer cannot change the PATH of the shell that launched it.
  Open a new terminal, run: source "${PROFILE_FILE}", or run:
  ${PATH_LINE}

After reloading your shell, run:
  git vibe version
EOF
