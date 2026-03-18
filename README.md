# Git Vibe

Git Vibe is a lightweight Git workflow for teams that ship from `main`, keep all work on `feat/*` branches, and treat every `feat/*` branch as a worktree from the moment it is created.

The command surface is intentionally small:

- `git vibe code <name>`
- `git vibe issue <number>`
- `git vibe pr`
- `git vibe submit`
- `git vibe enter [name]`
- `git vibe open [name]`
- `git vibe diff [name]`
- `git vibe check [name]`
- `git vibe checks [name]`
- `git vibe finish <name>`
- `git vibe release <version>`
- `git vibe ship <version>`
- `git vibe release <version> --push`
- `git vibe list`
- `git vibe status [name]`
- `git vibe doctor [--repair]`
- `git vibe prune`

Under the hood, every vibe is a short-lived `feat/*` branch that is created as its own worktree. That gives humans and AI agents isolated lanes to work in without polluting `main`.

## Why Git Vibe

Classic `git-flow` assumes a world with long-lived `develop` branches, release branches, and slow integration. Git Vibe keeps the parts that still matter and drops the ceremony:

- `main` is the only long-lived branch.
- Every work branch starts as `feat/<slug>`, including fixes and urgent patches.
- Every `feat/*` branch is created as its own worktree.
- `main` stays clean and deployable.
- Releases are cut directly from `main` with a release commit and a tag.

This is a better fit for fast-moving teams and AI-assisted development, where multiple experiments can happen in parallel and isolation matters more than branch hierarchy.

Git Vibe is also built for AI orchestration. When every `feat/*` branch gets its own worktree by default, you can safely run multiple agents, terminals, test runs, and experiments side by side without branch hopping, stash juggling, or cross-task contamination.

## What the workflow includes

- A portable `git-vibe` executable exposed as `git vibe ...`
- `code`, `issue`, `pr`, `submit`, `enter`, `open`, `diff`, `finish`, `release`, `ship`, `list`, `status`, `check`, `checks`, `path`, `doctor`, `prune`, and `version` commands
- Global hook wrappers for `pre-commit`, `commit-msg`, and `pre-push`
- Semantic commit enforcement
- Base-branch protection against direct commits and pushes
- Default worktree layout under `../.vibe/<repo>/<slug>`
- A simple workflow for human and AI parallel work without `develop`, `fix/*`, or `release/*` branches

## Install

Quick install:

```bash
curl -fsSL https://raw.githubusercontent.com/sailscastshq/git-vibe/main/install.sh | bash
```

Install the Git Vibe skill too:

```bash
npx skills add sailscastshq/git-vibe
```

To install a specific version, pin the ref:

```bash
curl -fsSL https://raw.githubusercontent.com/sailscastshq/git-vibe/v0.0.1/install.sh | GIT_VIBE_REF=v0.0.1 bash
```

If you are working from a local checkout, `./install.sh` still works.

The installer:

- copies `git-vibe` into `~/.git-vibe/bin`
- installs global Git hooks into `~/.git-vibe/hooks`
- creates a global Git alias so `git vibe` works even before a shell reload
- creates short Git aliases for `git vc` and `git vr`
- sets `core.hooksPath` globally
- seeds these defaults:
  - `vibe.baseBranch=main`
  - `vibe.branchPrefix=feat/`
  - `vibe.worktreeRoot=../.vibe`
- appends `~/.git-vibe/bin` to your shell profile if it is not already managed by Git Vibe
- installs shell integration so `git vibe code ...` and `git vibe enter ...` move you into the target worktree and `git vibe finish ...` brings you back to the main worktree after cleanup

Editor launch defaults to `auto`, which means Git Vibe opens a workspace app only in interactive terminals. You can override that per repo or globally with `vibe.openEditor=auto|always|never`.

If you want the standalone `git-vibe` binary on your shell `PATH`, the installer adds this line to your shell profile:

```bash
export PATH="$HOME/.git-vibe/bin:$PATH"
```

Because installers run in a child shell, they cannot modify the current terminal session that launched them. `git vibe ...` works immediately through the Git alias, but a fresh terminal or `source ~/.zshrc` is still needed before direct `git-vibe` usage and the auto-jump shell integration are available in that shell.

Then verify the install:

```bash
git vibe version
```

After your shell profile is loaded, this should also work the way you expect:

```bash
git vibe code fallback-app-urls
```

You will land inside the worktree automatically, and in interactive terminals Git Vibe will also open that worktree in your configured workspace app. In a Codex Desktop shell it prefers Codex. Otherwise it prefers VS Code when the `code` CLI is installed. In a VS Code terminal it reuses the current window so Source Control follows the feature worktree instead of staying on the base repo.

If you prefer short aliases, the installer also gives you:

```bash
git vc fallback-app-urls
git vr 0.0.2 --push
```

If your team starts from GitHub issues, Git Vibe can also start directly from an issue number:

```bash
git vibe code 9
git vibe issue 9
```

After you’ve made the change, Git Vibe can also open the PR for you:

```bash
git vibe pr
git vibe submit
```

## Workflow

Start a vibe from a clean `main` checkout:

```bash
git switch main
git pull --ff-only origin main
git vibe code fallback-app-urls
```

That creates:

- branch: `feat/fallback-app-urls`
- worktree: `../.vibe/<repo>/fallback-app-urls`

Do all work inside that worktree. Even fixes and urgent patches still live under `feat/*`.

If you rerun `git vibe code fallback-app-urls`, Git Vibe reopens the existing worktree instead of creating a duplicate branch.

If you start from an issue number, Git Vibe fetches the issue title through `gh` and creates a deterministic branch such as `feat/9-issue-aware-vibe-creation`. Later reruns of `git vibe code 9` or `git vibe issue 9` reopen that same vibe even if the issue title changes on GitHub.

When it opens or reopens a vibe, Git Vibe also prints a short workspace summary with the branch, base, path, compare target, and current change state. That makes the worktree feel anchored even in tools that do not visibly switch context for you.

If a tool still looks visually anchored to the base checkout, you can explicitly jump back into a vibe later with:

```bash
git vibe enter fallback-app-urls
```

If you want to reopen the same vibe directly in Codex Desktop or VS Code, use:

```bash
git vibe open fallback-app-urls
```

When the feature is merged locally:

```bash
git vibe finish --local fallback-app-urls
```

When you want the default auto-cleanup behavior:

```bash
git vibe finish fallback-app-urls
```

When the feature was merged remotely through a PR:

```bash
git fetch origin main
git vibe finish fallback-app-urls
```

Or let Git Vibe fetch before it checks:

```bash
git vibe finish --sync fallback-app-urls
```

The preferred GitHub-native loop is now:

```bash
git vibe issue 9
git commit -m "feat: implement the change"
git vibe pr
git vibe check
git vibe finish --sync 9
```

When you want a quick control-tower view of every open vibe, or you suspect a stale worktree after moving or deleting folders by hand, use:

```bash
git vibe list
git vibe doctor
```

## Commands

### `git vibe code [--editor] [--no-editor] [--codex|--vscode] <name|number>`

Creates or reopens a `feat/<slug>` worktree. If the vibe does not exist yet, Git Vibe creates the branch from `main` and opens it. If it already exists, Git Vibe jumps back into that same worktree instead of creating a duplicate.

Example:

```bash
git vibe code add-billing-webhook
```

If you pass a GitHub issue number instead of a name, Git Vibe uses `gh issue view` to derive the branch slug and remembers the issue-to-branch mapping locally:

```bash
git vibe code 9
```

Workspace launch follows `vibe.openEditor`, which accepts `auto`, `always`, or `never`.

- `auto` is the default and opens VS Code only in interactive terminals
- `always` opens your configured workspace app whenever its CLI is available
- `never` skips workspace launch

Use `--editor` or `--no-editor` to override the launch policy for a single run. Use `--codex` or `--vscode` when you want to force a specific app for that one command.

After opening a vibe, Git Vibe prints a context summary with the branch, base, path, compare target, and current change state so you can orient yourself quickly in Codex, VS Code, or a plain terminal.

### `git vibe issue [--editor] [--no-editor] [--codex|--vscode] <number>`

Explicit issue-first alias for `git vibe code <number>`.

- use this when you want the CLI to read clearly as “start work from issue 9”
- Git Vibe requires `gh` only when it needs to fetch issue metadata for a new issue-driven vibe
- once the vibe exists, Git Vibe can reopen it by issue number from the stored branch mapping

### `git vibe pr [--draft] [--web] [--title <title>] [--body <body>] [name]`

Creates a pull request for the current vibe, or for the named vibe when run from `main`.

- pushes the vibe branch to `origin` first when needed
- uses the linked issue title as the default PR title when the vibe came from an issue
- builds a default PR body from recent commit subjects and adds `Closes #<issue>` for issue-linked vibes
- keeps `gh` as the underlying engine so the actual PR still lives in normal GitHub workflows

### `git vibe submit [--draft] [--web] [--title <title>] [--body <body>] [name]`

Alias for `git vibe pr`.

### `git vibe enter [name]`

Jumps back into an existing vibe worktree and prints the same focused context summary.

- run it from `main` with a vibe name when you want to reopen a specific lane
- run it inside a vibe with no name to confirm where you are and re-anchor the current workspace
- shell integration uses it for an explicit "take me there" flow when `git vibe code ...` was not the command that opened your current terminal

### `git vibe open [--codex|--vscode] [name]`

Reopens an existing vibe in Codex Desktop or VS Code and prints the same focused context summary.

- run it from `main` with a vibe name when the shell is in one place but you want the app to follow the worktree
- run it inside a vibe with no name to reopen the current lane in your workspace app
- use `--codex` or `--vscode` to force a target app for one run

### `git vibe diff [name]`

Shows the current vibe's cumulative diff against its base branch.

- run it inside a vibe worktree with no name to inspect the current lane
- pass a vibe name from `main` when you want to inspect another active worktree
- untracked files are called out explicitly so they do not disappear from the mental model

### `git vibe finish [--local] [--sync] [name]`

Finishes a vibe safely.

- With no flag, `git vibe finish <name>` uses the default auto mode. It checks local `main` and your current `origin/main` refs, then cleans up if the branch is already merged.
- If the branch is already merged into local `main`, it cleans up the worktree and deletes the branch.
- If the branch is merged into `origin/main`, it fast-forwards local `main`, then cleans up.
- If you pass `--local`, it merges the branch into local `main` with `--ff-only`, then cleans up.
- If you pass `--sync`, it fetches `origin/main` first, then runs the same cleanup check with fresh remote refs.

Run it with no name from inside a feature worktree to finish the current vibe.

Use `finish` when the branch lifecycle is complete. Use `doctor` or `prune` when the branch is still open but the worktree metadata got out of sync.

### `git vibe release <version> [--push]`

Cuts a release directly from `main`. Git Vibe creates a `chore(release): vX.Y.Z` commit on `main` and adds an annotated `vX.Y.Z` tag. If the repo already has a top-level `VERSION` file, or you configure `vibe.releaseVersionFile`, Git Vibe updates that plain-text file too.

Example:

```bash
git switch main
git pull --ff-only origin main
git vibe release 0.0.2
```

The command is intentionally narrow:

- it must be run from `main`
- the working tree must be clean
- it creates the commit and tag locally
- it only auto-updates plain-text version files

If you want Git Vibe to push the release for you, use:

```bash
git vibe release 0.0.2 --push
```

That uses the maintainer override internally, so it still works even in repos that explicitly block raw `main` pushes.

### `git vibe ship <version> [--push]`

Alias for `git vibe release <version> [--push]`.

### `git vibe list`

Lists active feature worktrees for the current repository, including each vibe's state, ahead/behind count against the base branch, and a short change summary.

### `git vibe status [name]`

Shows the current repository, base branch, branch prefix, worktree root, and active vibes. When run inside a vibe worktree, or when you pass a vibe name, it also prints a focused workspace summary for that vibe, including linked PR state and a checks summary when available through `gh`.

### `git vibe check [name]`

Alias for `git vibe status [name]`.

### `git vibe checks [name]`

Shows the individual GitHub checks for the current vibe, or for the named vibe when run from `main`.

### `git vibe path <name>`

Prints the path for a vibe worktree.

### `git vibe doctor [--repair]`

Reports stale or broken vibe worktree metadata.

- use `git vibe doctor` when `git vibe list` shows a missing or prunable vibe, or after you moved or deleted a worktree folder outside Git
- use `git vibe doctor --repair` when you want Git Vibe to run `git worktree repair` and `git worktree prune` for you
- use this for worktree health problems, not for merged-branch cleanup

### `git vibe prune`

Runs `git worktree prune` to clean stale worktree metadata.

If you are unsure what is stale, prefer `git vibe doctor` first because it shows the affected vibes before you prune.

### `git vibe version`

Prints the installed Git Vibe version.

## Hooks

Git Vibe uses global hooks as guardrails, not as the workflow engine.

### `pre-commit`

Blocks direct commits on the base branch by default.

Override when you intentionally need a release or admin commit:

```bash
VIBE_ALLOW_COMMIT_BASE=1 git commit -m "chore(release): v0.0.1"
```

### `commit-msg`

Requires semantic commit messages.

Git Vibe standardizes branch names, not commit types. Branches always stay under `feat/*`, but commits can still use semantic types like `feat:`, `fix:`, `docs:`, `chore:`, and `test:`.

Accepted examples:

- `feat(cli): add finish --sync`
- `fix(hooks): allow release override`
- `chore(release): v0.0.1`

### `pre-push`

Allows pushes from the base branch by default.

If a repo wants Git Vibe to block raw `main` pushes again, opt into that explicitly:

```bash
git config vibe.disallowPushOnBase true
```

Then the escape hatch is still:

```bash
VIBE_ALLOW_PUSH_BASE=1 git push origin main
```

## Configuration

Git Vibe reads from Git config so you can keep global defaults and still override per repo.

Global defaults:

```bash
git config --global vibe.baseBranch main
git config --global vibe.branchPrefix feat/
git config --global vibe.worktreeRoot ../.vibe
```

Useful repo-level override example:

```bash
git config vibe.worktreeRoot ../worktrees
```

Editor launch policy:

```bash
git config --global vibe.openEditor auto
git config vibe.openEditor never
```

Workspace app selection:

```bash
git config --global vibe.openWorkspaceWith auto
git config vibe.openWorkspaceWith codex
```

`vibe.openWorkspaceWith=auto` prefers Codex Desktop inside a Codex shell and otherwise uses VS Code when available.

Issue-driven branch naming:

```bash
git config --global vibe.issueBranchStyle number-and-title
git config vibe.issueBranchStyle title-only
```

Supported values are:

- `number-and-title` for branches like `feat/9-issue-aware-vibe-creation`
- `number-only` for branches like `feat/9`
- `title-only` for branches like `feat/issue-aware-vibe-creation`

Git Vibe stores the issue-to-branch mapping locally so rerunning `git vibe code 9` keeps reopening the original vibe even if the GitHub issue title later changes.

To block raw `main` pushes in a specific repo:

```bash
git config vibe.disallowPushOnBase true
```

Release command example:

```bash
git config vibe.releaseVersionFile VERSION
```

`git vibe release` only auto-manages plain-text version files containing the version string by itself. If your project keeps its version in `package.json` or somewhere else, bump that file yourself before cutting the release. Without this config, Git Vibe auto-updates a top-level `VERSION` file when one already exists and otherwise skips version-file changes.

## Release and tagging

There is no `develop` branch in Git Vibe. Releases are cut directly from `main`.

The release flow is:

1. make sure every feature for the release is already merged into `main`
2. switch to `main`
3. fast-forward to the remote
4. run `git vibe release <version>` or `git vibe release <version> --push`
5. push `main` and the tag

For Git Vibe `0.0.2`, the commands are:

```bash
git switch main
git pull --ff-only origin main
git vibe release 0.0.2 --push
```

Under the hood, `git vibe release 0.0.2 --push` creates `chore(release): v0.0.2`, creates the annotated tag `v0.0.2` on `main`, and pushes both `main` and the tag to `origin`. If Git Vibe is managing a plain-text version file for that repo, it writes `0.0.2` there first.

## Development

Run the smoke test:

```bash
./tests/smoke.sh
```

## License

MIT
