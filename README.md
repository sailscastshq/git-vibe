# Git Vibe

Git Vibe is a lightweight Git workflow for teams that ship from `main`, keep all work on `feat/*` branches, and treat every `feat/*` branch as a worktree from the moment it is created.

The command surface is intentionally small:

- `git vibe code <name>`
- `git vibe finish <name>`
- `git vibe release <version>`
- `git vibe release <version> --push`
- `git vibe list`
- `git vibe status`
- `git vibe prune`

Under the hood, every vibe is a short-lived `feat/*` branch that is created as its own worktree. That gives humans and AI agents isolated lanes to work in without polluting `main`.

## Why Git Vibe

Classic `git-flow` assumes a world with long-lived `develop` branches, release branches, and slow integration. Git Vibe keeps the parts that still matter and drops the ceremony:

- `main` is the only long-lived branch.
- Every work branch starts as `feat/<slug>`, including fixes and urgent patches.
- Every `feat/*` branch is created as its own worktree.
- `main` stays clean and deployable.
- Releases are cut directly from `main` with a version bump commit and a tag.

This is a better fit for fast-moving teams and AI-assisted development, where multiple experiments can happen in parallel and isolation matters more than branch hierarchy.

Git Vibe is also built for AI orchestration. When every `feat/*` branch gets its own worktree by default, you can safely run multiple agents, terminals, test runs, and experiments side by side without branch hopping, stash juggling, or cross-task contamination.

## What the workflow includes

- A portable `git-vibe` executable exposed as `git vibe ...`
- `code`, `finish`, `release`, `list`, `status`, `path`, `prune`, and `version` commands
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
- installs shell integration so `git vibe code ...` moves you into the new worktree and `git vibe finish ...` brings you back to the main worktree after cleanup

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

You will land inside the worktree automatically, and if the VS Code `code` CLI is installed Git Vibe will also open that worktree in VS Code. In a VS Code terminal it replaces the current window so Source Control follows the feature worktree instead of staying on the base repo.

If you prefer short aliases, the installer also gives you:

```bash
git vc fallback-app-urls
git vr 0.0.2 --push
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

## Commands

### `git vibe code <name>`

Creates or reopens a `feat/<slug>` worktree. If the vibe does not exist yet, Git Vibe creates the branch from `main` and opens it. If it already exists, Git Vibe jumps back into that same worktree instead of creating a duplicate.

Example:

```bash
git vibe code add-billing-webhook
```

If the VS Code `code` CLI is available, `git vibe code ...` opens that worktree in VS Code too.

### `git vibe finish [--local] [--sync] [name]`

Finishes a vibe safely.

- With no flag, `git vibe finish <name>` uses the default auto mode. It checks local `main` and your current `origin/main` refs, then cleans up if the branch is already merged.
- If the branch is already merged into local `main`, it cleans up the worktree and deletes the branch.
- If the branch is merged into `origin/main`, it fast-forwards local `main`, then cleans up.
- If you pass `--local`, it merges the branch into local `main` with `--ff-only`, then cleans up.
- If you pass `--sync`, it fetches `origin/main` first, then runs the same cleanup check with fresh remote refs.

Run it with no name from inside a feature worktree to finish the current vibe.

### `git vibe release <version> [--push]`

Cuts a release directly from `main`. Git Vibe updates the plain-text `VERSION` file, creates a `chore(release): vX.Y.Z` commit on `main`, and adds an annotated `vX.Y.Z` tag.

Example:

```bash
git switch main
git pull --ff-only origin main
git vibe release 0.0.2
```

The command is intentionally narrow:

- it must be run from `main`
- the working tree must be clean
- it expects a plain-text version file at `VERSION`
- it creates the commit and tag locally

If you want Git Vibe to push the release for you, use:

```bash
git vibe release 0.0.2 --push
```

That uses the maintainer override internally, so it still works even in repos that explicitly block raw `main` pushes.

### `git vibe list`

Lists active feature worktrees for the current repository.

### `git vibe status`

Shows the current repository, base branch, branch prefix, worktree root, and active vibes.

### `git vibe path <name>`

Prints the path for a vibe worktree.

### `git vibe prune`

Runs `git worktree prune` to clean stale worktree metadata.

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

To block raw `main` pushes in a specific repo:

```bash
git config vibe.disallowPushOnBase true
```

Release command example:

```bash
git config vibe.releaseVersionFile VERSION
```

`git vibe release` expects that file to be a plain-text file containing only the version string.

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

Under the hood, `git vibe release 0.0.2 --push` writes `0.0.2` to `VERSION`, commits `chore(release): v0.0.2`, creates the annotated tag `v0.0.2` on `main`, and pushes both `main` and the tag to `origin`.

## Development

Run the smoke test:

```bash
./tests/smoke.sh
```

## License

MIT
