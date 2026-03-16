---
name: git-vibe-flow
description: Use this skill when working in a repository that follows Git Vibe Flow, where `main` is the only long-lived branch, all work branches stay under `feat/*`, every `feat/*` branch is created as a worktree, and releases are cut directly from `main` with annotated tags.
---

# Git Vibe Flow

Use this skill when the user wants to:

- start or finish work with `git vibe`
- apply a `main` plus `feat/*` workflow
- isolate tasks with worktrees
- coordinate parallel human and AI work safely
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

Start a vibe:

```bash
git vibe start <name>
```

Finish a vibe after a remote merge:

```bash
git vibe finish --sync <name>
```

Finish a vibe with a local fast-forward merge:

```bash
git vibe finish --local <name>
```

List active vibes:

```bash
git vibe list
```

## Branch and commit guidance

- Keep branch names under `feat/*` only.
- Continue using semantic commits like `feat:`, `fix:`, `docs:`, `chore:`, and `test:`.
- Do not introduce `develop`, `fix/*`, `hotfix/*`, or `release/*` unless the user explicitly wants to leave Git Vibe Flow.

## Release flow

```bash
git switch main
git pull --ff-only origin main
printf '0.0.1\n' > VERSION
git add VERSION
VIBE_ALLOW_COMMIT_BASE=1 git commit -m "chore(release): v0.0.1"
git tag -a v0.0.1 -m "v0.0.1"
VIBE_ALLOW_PUSH_BASE=1 git push origin main --tags
```

The tag always points at the release commit on `main`.

## Install

Quick install:

```bash
curl -fsSL https://raw.githubusercontent.com/sailscastshq/git-vibe/main/install.sh | bash
```

Pin a release:

```bash
curl -fsSL https://raw.githubusercontent.com/sailscastshq/git-vibe/v0.0.1/install.sh | GIT_VIBE_REF=v0.0.1 bash
```
