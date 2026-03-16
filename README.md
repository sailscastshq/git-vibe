# Git Vibe Flow

Git Vibe Flow is a lightweight Git workflow for teams that ship from `main`, work in `feat/*` branches, and want worktrees to be the default instead of an advanced trick.

The command surface is intentionally small:

- `git vibe start <name>`
- `git vibe finish <name>`
- `git vibe list`
- `git vibe status`
- `git vibe prune`

Under the hood, every vibe is a short-lived `feat/*` branch paired with its own worktree. That gives humans and AI agents isolated lanes to work in without polluting `main`.

## Why Git Vibe Flow

Classic `git-flow` assumes a world with long-lived `develop` branches, release branches, and slow integration. Git Vibe Flow keeps the parts that still matter and drops the ceremony:

- `main` is the only long-lived branch.
- Every task starts as `feat/<slug>`.
- Every feature gets a worktree by default.
- `main` stays clean and deployable.
- Releases are cut directly from `main` with a version bump commit and a tag.

This is a better fit for fast-moving teams and AI-assisted development, where multiple experiments can happen in parallel and isolation matters more than branch hierarchy.

## What v0.0.1 includes

- A portable `git-vibe` executable exposed as `git vibe ...`
- `start`, `finish`, `list`, `status`, `path`, `prune`, and `version` commands
- Global hook wrappers for `pre-commit`, `commit-msg`, and `pre-push`
- Semantic commit enforcement
- Base-branch protection against direct commits and pushes
- Default worktree layout under `../.vibe/<repo>/<slug>`

## Install

Clone the repo somewhere you keep tooling, then run:

```bash
./install.sh
```

The installer:

- copies `git-vibe` into `~/.git-vibe/bin`
- installs global Git hooks into `~/.git-vibe/hooks`
- sets `core.hooksPath` globally
- seeds these defaults:
  - `vibe.baseBranch=main`
  - `vibe.branchPrefix=feat/`
  - `vibe.worktreeRoot=../.vibe`

If `~/.git-vibe/bin` is not on your `PATH`, add this to your shell profile:

```bash
export PATH="$HOME/.git-vibe/bin:$PATH"
```

Then reload your shell and verify the install:

```bash
git vibe version
```

## Workflow

Start a vibe from a clean `main` checkout:

```bash
git switch main
git pull --ff-only origin main
git vibe start fallback-app-urls
```

That creates:

- branch: `feat/fallback-app-urls`
- worktree: `../.vibe/<repo>/fallback-app-urls`

Do all work inside that worktree.

When the feature is merged locally:

```bash
git vibe finish --local fallback-app-urls
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

### `git vibe start <name>`

Creates a `feat/<slug>` branch from `main` and attaches it to a new worktree.

Example:

```bash
git vibe start add-billing-webhook
```

### `git vibe finish [--local] [--sync] [name]`

Finishes a vibe safely.

- If the branch is already merged into local `main`, it cleans up the worktree and deletes the branch.
- If the branch is merged into `origin/main`, it fast-forwards local `main`, then cleans up.
- If you pass `--local`, it merges the branch into local `main` with `--ff-only`, then cleans up.

Run it with no name from inside a feature worktree to finish the current vibe.

### `git vibe list`

Lists active feature worktrees for the current repository.

### `git vibe status`

Shows the current repository, base branch, branch prefix, worktree root, and active vibes.

### `git vibe path <name>`

Prints the path for a vibe worktree.

### `git vibe prune`

Runs `git worktree prune` to clean stale worktree metadata.

### `git vibe version`

Prints the installed Git Vibe Flow version.

## Hooks

Git Vibe Flow uses global hooks as guardrails, not as the workflow engine.

### `pre-commit`

Blocks direct commits on the base branch by default.

Override when you intentionally need a release or admin commit:

```bash
VIBE_ALLOW_COMMIT_BASE=1 git commit -m "chore(release): v0.0.1"
```

### `commit-msg`

Requires semantic commit messages.

Accepted examples:

- `feat(cli): add finish --sync`
- `fix(hooks): allow release override`
- `chore(release): v0.0.1`

### `pre-push`

Blocks direct pushes from the base branch by default.

Override when you intentionally need to push `main`:

```bash
VIBE_ALLOW_PUSH_BASE=1 git push origin main
```

## Configuration

Git Vibe Flow reads from Git config so you can keep global defaults and still override per repo.

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

## Release and tagging

There is no `develop` branch in Git Vibe Flow. Releases are cut directly from `main`.

The release flow is:

1. make sure every feature for the release is already merged into `main`
2. switch to `main`
3. fast-forward to the remote
4. bump the version
5. create a release commit on `main`
6. create an annotated tag
7. push `main` and the tag

For Git Vibe Flow `0.0.1`, the commands are:

```bash
git switch main
git pull --ff-only origin main
printf '0.0.1\n' > VERSION
git add VERSION
VIBE_ALLOW_COMMIT_BASE=1 git commit -m "chore(release): v0.0.1"
git tag -a v0.0.1 -m "v0.0.1"
VIBE_ALLOW_PUSH_BASE=1 git push origin main --tags
```

The key point is simple: without `develop`, the tag is created on the release commit that lives on `main`.

## Development

Run the smoke test:

```bash
./tests/smoke.sh
```

## License

MIT
