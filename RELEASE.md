# Git Vibe Flow v0.0.1

Git Vibe Flow is a lightweight Git workflow for teams that ship from `main`, keep every work branch under `feat/*`, and create every `feat/*` branch as its own worktree.

It is designed for modern human and AI orchestration: one task, one branch, one worktree, one clean lane of work.

## Why this exists

Classic `git-flow` was built for a different world. Git Vibe Flow is for teams that:

- do not want `develop`
- do not use `fix/*`, `hotfix/*`, or `release/*`
- want `main` to stay deployable
- want multiple humans and AI agents to work in parallel without stepping on each other
- want worktrees to be normal, not an advanced Git trick

## Highlights

- `git vibe` works as a native Git subcommand
- every new vibe creates a `feat/<slug>` branch as its own worktree
- all work branches stay under `feat/*`, even for fixes and urgent patches
- `finish` can clean up after a remote PR merge or perform a local fast-forward merge
- global hooks protect `main` from direct commits and pushes
- semantic commit messages are enforced
- releases are cut directly from `main` with a version bump commit and an annotated tag

## Included in 0.0.1

- `git vibe start <name>`
- `git vibe finish [--local] [--sync] [name]`
- `git vibe list`
- `git vibe status`
- `git vibe path <name>`
- `git vibe prune`
- `git vibe version`
- a curl-first installer
- global hook wrappers for `pre-commit`, `commit-msg`, and `pre-push`
- smoke test coverage for the core start and finish flow

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/sailscastshq/git-vibe/v0.0.1/install.sh | GIT_VIBE_REF=v0.0.1 bash
```

## Notes

- Git Vibe Flow standardizes branch naming, not commit types. Commits can still use `feat:`, `fix:`, `docs:`, `chore:`, and other semantic commit types.
- The first release is intentionally shell-based for portability and low install friction.
- The release tag for this version is `v0.0.1`.
