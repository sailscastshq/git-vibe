---
name: git-vibe
description: Use this skill when working in a repository that follows Git Vibe Flow, where `main` is the only long-lived branch, all work branches stay under `feat/*`, every `feat/*` branch is created as a worktree, and releases are cut directly from `main` with annotated tags.
---

# Git Vibe Flow

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

Git Vibe Flow is optimized for AI orchestration and parallel work. The point is to make the safe path the easy path:

- no `develop`
- no `fix/*`, `hotfix/*`, or `release/*`
- no stash-heavy branch hopping
- no mixing unrelated AI-generated diffs in one checkout

## Commands

Open a vibe:

```bash
git vibe code <name>
```

Finish a vibe after a remote merge:

```bash
git vibe finish --sync <name>
```

Finish a vibe with a local fast-forward merge:

```bash
git vibe finish --local <name>
```

Cut a release directly from `main`:

```bash
git vibe release <version>
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
- Do not introduce `develop`, `fix/*`, `hotfix/*`, or `release/*` unless the user explicitly wants to leave Git Vibe Flow.

## Hook behavior and overrides

- Direct commits on `main` are blocked by default.
- Direct pushes on `main` are blocked by default.
- Semantic commit messages are enforced by the global hooks.

Use these overrides only for deliberate maintainer actions such as release commits:

```bash
VIBE_ALLOW_COMMIT_BASE=1 git commit -m "chore(release): v0.0.1"
VIBE_ALLOW_PUSH_BASE=1 git push origin main
```

## Release flow

```bash
git switch main
git pull --ff-only origin main
git vibe release 0.0.2
VIBE_ALLOW_PUSH_BASE=1 git push origin main --tags
```

The release command updates the plain-text `VERSION` file, creates `chore(release): vX.Y.Z` on `main`, and adds the annotated `vX.Y.Z` tag.

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

- sets a global Git alias so `git vibe ...` works immediately
- appends `~/.git-vibe/bin` to the shell profile so `git-vibe ...` works in future terminals
- installs shell integration so `git vibe code ...` and `git vibe finish ...` can move between worktrees automatically
