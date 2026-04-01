---
name: git-vibe
description: Use this skill when working in a repository that follows Git Vibe, where `main` is the only long-lived branch, all work branches stay under `feat/*`, worktree mode is the default, solo mode is available for single-checkout work, and releases are cut directly from `main` with annotated tags.
---

# Git Vibe

Use this skill when the user wants to:

- open or finish work with `git vibe`
- apply a `main` plus `feat/*` workflow
- isolate tasks with worktrees
- keep branch work in one checkout with solo mode
- coordinate parallel human and AI work safely
- inspect active vibes or worktree paths
- cut a release directly from `main`

## Core rules

- `main` is the only long-lived branch.
- All work branches use `feat/<slug>`, even for bug fixes and urgent patches.
- `worktree` is the built-in default mode.
- `worktree` mode creates each `feat/*` branch as its own worktree.
- `solo` mode creates or switches the `feat/*` branch in the current checkout.
- `main` should remain clean and deployable.
- Releases happen directly on `main` with a release commit and an annotated tag.

## Why this workflow exists

Git Vibe is optimized for AI orchestration and parallel work. The point is to make the safe path the easy path:

- no `develop`
- no `fix/*`, `hotfix/*`, or `release/*`
- no stash-heavy branch hopping
- no mixing unrelated AI-generated diffs in one checkout

When the user is mostly doing one branch at a time, quick UI tweaks, or `npm run dev` loops in a single checkout, prefer `solo` mode. When the user wants parallel human or AI lanes, prefer the default `worktree` mode.

## Commands

Open a vibe:

```bash
git vibe code <name>
git vibe code --solo <name>
git vibe code --worktree <name>
```

Attach agent session context while you open it:

```bash
git vibe code --agent codex --task "fix login redirect" <name>
```

Open a vibe directly from a GitHub issue:

```bash
git vibe code <number>
git vibe issue <number>
```

Open a pull request from the current vibe:

```bash
git vibe pr
git vibe submit
```

Workspace launch follows `vibe.openEditor=auto|always|never`. The default is `auto`, which opens a workspace app only in interactive terminals. Use `--editor` or `--no-editor` to override that for one run, and `--codex` or `--vscode` to force the target app. After opening a vibe, Git Vibe should print enough branch/base/diff context that the worktree feels anchored even when the editor or terminal does not visibly switch for you. Fresh vibes should also inherit shared runtime paths from the primary checkout before any `post-create` hook runs. The built-in default is `node_modules`, repos can override or extend it with `vibe.sharedPaths`, and linked paths should be added to the worktree-local exclude file so the vibe stays clean.

Git Vibe resolves mode with this precedence:

1. explicit `--solo` or `--worktree` flag on `code`, `issue`, or `start`
2. local repo Git config `vibe.mode`
3. repo-root `vibe.toml`
4. global Git config
5. built-in default `worktree`

When the effective mode is `solo`, `git vibe code`, `git vibe issue`, and `git vibe start` should create or switch the branch in the current checkout. `git vibe enter` should switch back to that branch in the same checkout and, unless shell-output mode is in use, honor the usual editor-launch policy so the lane can reopen in VS Code or Codex without moving paths. `git vibe open` should switch the branch first and then reopen the same checkout in the configured workspace app.

Issue-driven vibes use `gh issue view` to build deterministic branch names. `vibe.issueBranchStyle=number-and-title|number-only|title-only` controls the naming shape, and Git Vibe remembers the issue-to-branch mapping locally so later issue-title edits do not break reopen flows.

Shared repo defaults should live in a checked-in `vibe.toml`, not only in ad hoc local Git config. The precedence should be:

1. local repo Git config
2. repo-root `vibe.toml`
3. global Git config
4. built-in defaults

Keep the `vibe.toml` format intentionally small. Git Vibe only needs straightforward scalar settings under `[vibe]` plus lifecycle commands under `[hooks]`. Use `sharedPaths = "node_modules,.venv"` when a repo wants fresh vibes to reuse base-checkout runtime plumbing.

`vibe.mode = "solo"` is the right recommendation when the user usually has one active branch at a time and wants the editor to stay on the same checkout. `vibe.mode = "worktree"` is the right recommendation when the user is running multiple tasks, agents, or experiments in parallel.

PR-driven handoff uses `gh pr create`, `gh pr view`, and `gh pr checks` so the workflow stays GitHub-native. `git vibe check` should surface PR/check summary when available, and `git vibe checks` should let users inspect the individual checks without leaving the vibe flow.

Jump back into an existing vibe:

```bash
git vibe enter <name>
```

Reopen an existing vibe in Codex Desktop or VS Code:

```bash
git vibe open <name>
```

Inspect or update vibe session metadata:

```bash
git vibe session <name>
git vibe session --task "polish pricing copy" <name>
```

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

`git vibe list` should act like a control tower for the repo. It should show active vibe branches, worktree state like `clean`, `dirty`, `locked`, or `prunable`, ahead/behind against the base branch, lightweight session context when present, and a short change summary.

In `solo` mode, `git vibe list` should still show branch-only vibes even when they are not currently checked out. `git vibe path` should return the current checkout path for solo vibes and the worktree path for worktree-backed vibes.

Show vibe status:

```bash
git vibe status
```

`git vibe status` or `git vibe check` should stay useful both from `main` and from inside a vibe checkout. When run inside a worktree-backed vibe, the reported vibe root should still point at the shared repo-level worktree area, not a nested path under the current worktree. If a vibe has saved session metadata, status should surface the agent label, task, last activity, configured mode, and actual backing clearly enough that a human can resume the lane without guessing. It should also show the active shared path plumbing so runtime setup is visible instead of magical.

Show the path for a vibe:

```bash
git vibe path <name>
```

Inspect and repair worktree metadata:

```bash
git vibe doctor
git vibe doctor --repair
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

The release command creates `chore(release): vX.Y.Z` on `main`, adds the annotated `vX.Y.Z` tag, and can push `main` plus the tag to `origin` when you pass `--push`. Version file updates should be configured through release versioning modes, not assumed globally.

Release versioning should look like this:

- `none` means Git Vibe only creates the release commit and tag
- `file` means Git Vibe updates a plain-text version file like `VERSION`
- `npm` means Git Vibe updates `package.json` and any existing npm lockfile
- checked-in repos should prefer `[release] versioning = "..."` in `vibe.toml`
- local overrides can use `git config vibe.releaseVersioning ...` and `git config vibe.releaseFile ...`

## Finish modes

- `git vibe finish <name>` is the default auto mode. It checks whether the vibe is already merged into local `main` or your current `origin/main` refs, then cleans up if it is.
- `git vibe finish --sync <name>` fetches `origin/main` first, then runs the same merge check. Use this after a PR was merged on GitHub and your local refs may be stale.
- `git vibe finish --local <name>` merges the vibe into local `main` with `--ff-only`, then cleans up.
- `git vibe finish --delete-remote <name>` also deletes `origin/<branch>` after merge verification. If `vibe.deleteRemoteOnFinish=true` in `vibe.toml` or local Git config, that remote cleanup becomes the repo default unless the user passes `--keep-remote`.

Keep `auto` as the default. It works offline, it does not force a network call, and it does not silently merge into `main`. Use `--sync` when you want fresh remote knowledge and `--local` when you want Git Vibe to perform the merge itself.

Use `git vibe finish` when the branch lifecycle is complete. Use `git vibe doctor` when the branch is still active but the worktree metadata looks stale, missing, prunable, or otherwise unhealthy. Use raw `git vibe prune` as the lower-level cleanup command when you already know you just want to drop stale metadata.

Agent-aware metadata should stay lightweight and local-first:

- record session context with `git vibe code --agent/--task ...` or `git vibe session ...`
- show it in `list`, `status`, `check`, `enter`, and `open`
- update last activity when a user returns to a vibe
- clear the metadata automatically when the vibe is finished

Remote cleanup should stay safe and boring:

- deleting a remote feature branch should only happen after merge verification succeeds
- an already deleted remote branch should be treated as a successful no-op
- `git vibe status` should show whether `vibe.deleteRemoteOnFinish` is enabled for the repo, plus the active `vibe.toml` path and configured lifecycle hooks

Lifecycle hooks should stay explicit and narrow:

- `post-create` is for setup after a brand-new vibe worktree is created, attached, or checked out, after shared path plumbing is linked
- `pre-finish` is for validation or cleanup just before Git Vibe removes the worktree and branch
- `pre-release` is for checks that must pass before Git Vibe mutates the version file, creates the release commit, or tags
- hooks should be optional, repo-local, and abort the command when they fail

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
- installs shell integration so `git vibe code ...`, `git vibe enter ...`, `git vibe finish ...`, and `git vc ...` can move between worktrees automatically
