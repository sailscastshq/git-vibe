---
name: git-vibe
description: Use this skill when working in a repository that follows Git Vibe, where `main` is the only long-lived branch, all work branches stay under `feat/*`, every `feat/*` branch is created as a worktree, and releases are cut directly from `main` with annotated tags.
---

# Git Vibe

Use this skill when the user wants to:

- open or finish work with `git vibe`
- apply a `main` plus `feat/*` workflow
- isolate tasks with worktrees
- coordinate parallel human and AI work safely
- inspect active vibes or worktree paths
- cut a release directly from `main`

## Core rules

- `main` is the only long-lived branch.
- All work branches use `feat/<slug>`, even for bug fixes and urgent patches.
- Every `feat/*` branch is created as its own worktree.
- `main` should remain clean and deployable.
- Releases happen directly on `main` with a release commit and an annotated tag.

## Why this workflow exists

Git Vibe is optimized for AI orchestration and parallel work. The point is to make the safe path the easy path:

- no `develop`
- no `fix/*`, `hotfix/*`, or `release/*`
- no stash-heavy branch hopping
- no mixing unrelated AI-generated diffs in one checkout

## Commands

Open a vibe:

```bash
git vibe code <name>
```

Editor launch follows `vibe.openEditor=auto|always|never`. The default is `auto`, which opens VS Code only in interactive terminals. Use `--editor` or `--no-editor` to override that for one run. After opening a vibe, Git Vibe should print enough branch/base/diff context that the worktree feels anchored even when the editor or terminal does not visibly switch for you.

Inspect a vibe diff:

```bash
git vibe diff <name>
```

Check vibe context:

```bash
git vibe check <name>
```

Open a vibe with the short alias:

```bash
git vc <name>
```

Finish a vibe after a remote merge:

```bash
git vibe finish --sync <name>
```

Finish a vibe with a local fast-forward merge:

```bash
git vibe finish --local <name>
```

Finish a vibe in the default auto mode:

```bash
git vibe finish <name>
```

Cut a release directly from `main`:

```bash
git vibe release <version>
```

Cut and push a release directly from `main`:

```bash
git vibe release <version> --push
```

Cut a release with the friendlier alias:

```bash
git vibe ship <version> --push
```

Cut a release with the short alias:

```bash
git vr <version>
```

List active vibes:

```bash
git vibe list
```

Show vibe status:

```bash
git vibe status
```

Show the path for a vibe:

```bash
git vibe path <name>
```

Prune stale worktree metadata:

```bash
git vibe prune
```

Check the installed version:

```bash
git vibe version
```

## Branch and commit guidance

- Keep branch names under `feat/*` only.
- Continue using semantic commits like `feat:`, `fix:`, `docs:`, `chore:`, and `test:`.
- Do not introduce `develop`, `fix/*`, `hotfix/*`, or `release/*` unless the user explicitly wants to leave Git Vibe.

## Hook behavior and overrides

- Direct commits on `main` are blocked by default.
- Direct pushes on `main` are allowed by default.
- Semantic commit messages are enforced by the global hooks.

Use these overrides only for deliberate maintainer actions such as release commits or for repos that explicitly block raw `main` pushes:

```bash
VIBE_ALLOW_COMMIT_BASE=1 git commit -m "chore(release): v0.0.1"
VIBE_ALLOW_PUSH_BASE=1 git push origin main
```

If a repo wants Git Vibe to block raw `main` pushes again, set:

```bash
git config vibe.disallowPushOnBase true
```

## Release flow

```bash
git switch main
git pull --ff-only origin main
git vibe release 0.0.2 --push
```

The release command creates `chore(release): vX.Y.Z` on `main`, adds the annotated `vX.Y.Z` tag, and can push `main` plus the tag to `origin` when you pass `--push`. If the repo already has a top-level `VERSION` file, or you configure `vibe.releaseVersionFile`, Git Vibe updates that plain-text file too.

## Finish modes

- `git vibe finish <name>` is the default auto mode. It checks whether the vibe is already merged into local `main` or your current `origin/main` refs, then cleans up if it is.
- `git vibe finish --sync <name>` fetches `origin/main` first, then runs the same merge check. Use this after a PR was merged on GitHub and your local refs may be stale.
- `git vibe finish --local <name>` merges the vibe into local `main` with `--ff-only`, then cleans up.

Keep `auto` as the default. It works offline, it does not force a network call, and it does not silently merge into `main`. Use `--sync` when you want fresh remote knowledge and `--local` when you want Git Vibe to perform the merge itself.

## Install

Quick install:

```bash
curl -fsSL https://raw.githubusercontent.com/sailscastshq/git-vibe/main/install.sh | bash
```

Pin a release:

```bash
curl -fsSL https://raw.githubusercontent.com/sailscastshq/git-vibe/v0.0.1/install.sh | GIT_VIBE_REF=v0.0.1 bash
```

The installer does two important things:

- sets global Git aliases so `git vibe ...`, `git vc ...`, and `git vr ...` work immediately
- appends `~/.git-vibe/bin` to the shell profile so `git-vibe ...` works in future terminals
- installs shell integration so `git vibe code ...`, `git vibe finish ...`, and `git vc ...` can move between worktrees automatically
