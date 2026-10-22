---
name: jj
description: "Use Jujutsu (jj) for version control in jj-managed repos, including non-interactive hunk/line-level split and squash via jj-hunk-tool. Activate on VCS operations (status, commit, split, squash, absorb, rebase, bookmark, push) when a repo has .jj/, or when HEAD is detached. Read agent safety rules before running jj; prefer jj over git mutations."
token_cost: 180
related: [git]
keywords:
  [
    "jujutsu",
    "jj",
    "commit",
    "branch",
    "bookmark",
    "rebase",
    "squash",
    "split",
    "hunk",
    "partial-file",
    "absorb",
    "push",
    "immutable",
    "stash",
    "vcs",
    "version-control",
  ]
allowed-tools: Bash(jj *), Bash(jj-hunk-tool *), Bash(git log *), Bash(git diff *), Bash(git status *)
---

# Jujutsu (jj) Version Control

jj is a Git-compatible VCS with mutable commits and automatic rebasing. You use jj locally; the remote stays plain Git, so GitHub and collaborators see ordinary commits and branches.

**Original skill targeted jj v0.44.0**. `jj-hunk-tool` examples follow [mvzink/jj-hunk-tool](https://github.com/mvzink/jj-hunk-tool); check the installed versions when flags differ.

## Agent Safety Rules (Read First)

When running as an automated agent:

1. **Use `--no-pager` on output-producing `jj` commands.** A pager (like `less`) can hang the agent. `jj-hunk-tool` has its own CLI; do not pass it `--no-pager`.

   ```bash
   jj --no-pager log          # NOT: jj log
   jj --no-pager diff --git   # NOT: jj diff
   jj --no-pager show <id>    # NOT: jj show <id>
   ```

2. **Provide messages explicitly whenever jj may request one.** Use `-m` for split/describe/new/commit; for squash, choose `-m` or `-u` deliberately if a description merge could prompt an editor. Editor prompts fail in non-interactive environments.

   ```bash
   jj desc -m "message"      # NOT: jj desc
   jj new -m "message"       # NOT: jj new (then editor)
   ```

3. **Never run interactive commands.** These open a TUI/diff editor and hang the agent:

   - bare `jj split` (diff editor) — use `jj split -m "..." <filesets>` or `jj-hunk-tool split` instead
   - `jj squash -i` and bare `jj diffedit`
   - `jj-hunk-tool absorb -i` (prompts per hunk)
   - `jj resolve` (conflict editor) — resolve conflicts by editing files directly
   - any `jj desc` / `jj commit` without `-m`

4. **Verify history mutations.** Use `jj --no-pager status` and inspect the diffs of the *affected revisions* with `jj --no-pager diff --git -r <change-id>`. Status alone cannot confirm the right hunks moved. Check both sides of a split or squash, especially outside `@`.

## Core Mental Model

- **The working copy IS a change** (referenced as `@`). Every file modification is instantly tracked in the current change. No staging area, no `git add`, no stash, no commit ceremony.
- **Changes are mutable.** You can edit, reorder, squash, split, and rebase them freely; descendants auto-rebase. This is the core difference from Git, and the source of jj's power — and of the need to verify mutations.
- **Change ID vs Commit ID.** The Change ID (e.g. `tqpwlqmp`) is stable across rewrites — always reference changes by Change ID. The Commit ID (e.g. `3ccf7581`) is a content hash that changes whenever content changes. What you push to Git is the commit; what you track locally is the change.
- **Branches are bookmarks**, and you only need one when pushing to a remote. Local work is tracked by Change ID.
- **No detached HEAD.** `jj edit` jumps to any change and keeps working; descendants auto-rebase.
- **Recovery is strong, not guaranteed.** jj records every command in an operation log, so `jj undo` and `jj op restore` recover most mistakes — including abandons. This is not an absolute "nothing can ever be lost": concurrent operations and garbage collection have edge cases. Verify before you rely on recovery.

## Detecting / Setting Up a jj Repo

```bash
test -d .jj && echo "jj repo"        # if true, use jj for local operations
jj git init --colocate               # init jj in an existing git repo (keeps .git/)
jj git clone <url>                   # clone a git repo as a jj repo
```

If a repo has both `.jj/` and `.git/` (colocated), prefer jj commands for mutations; jj imports/exports Git automatically (see Git Bridge).

## Revsets

Revisions are selected with jj's revset language, used via `-r`:

- `@` — the working-copy change
- `@-` — the parent of the working copy
- `::@` — all ancestors of `@`
- `@::` — all descendants of `@`
- `trunk()..@` — commits between trunk and `@` (your branch)
- `bookmarks()` — all bookmarked changes
- `description("foo")` — changes whose description matches

Union is `a | b`, intersection is `a & b`, negation is `~a`. **Commas are not union.** Terse tips: prefer `@-` over `@~1` for the parent; use unique prefixes of change IDs (e.g. `kx` for `kxryzmsp`) when unambiguous.

```bash
jj --no-pager log -r 'trunk()..@'
```

## Essential Workflow

### Choose a task boundary

Check `jj st` and the current history before changing anything. If `@` contains unrelated work, create a new change or deliberately separate the work. Starting a described change up front is useful, but **anonymous `@` work followed by post-hoc splitting is valid**; do not manufacture separate commits or insist on preplanning for every edit.

```bash
jj new -m "Add user authentication to login endpoint"
# ... edit files — changes automatically become part of this change ...
jj st
```

### `jj new` creates a boundary when needed

`jj new` leaves the existing change as a parent and starts a fresh empty one — no staging or branch ceremony. Prefer it when you already know the boundary; use `split` afterward when the boundary only becomes clear during implementation.

## Viewing History

```bash
jj --no-pager log              # change graph + status (replaces git log + git status)
jj --no-pager log -p           # with patches
jj --no-pager show <change-id> # view a specific change
jj --no-pager diff --git       # working-copy diff in unified +/- format
jj --no-pager diff -r <id>     # diff of a specific change
```

**Always use `jj diff --git`.** The default `jj diff` output is a side-by-side line-numbered view (e.g. `26   26:`) that looks nothing like Git's `+`/`-` format — this is normal, not corruption. `--git` gives the familiar unified format.

## Working with Changes

### Moving between changes

```bash
jj new                 # seal current change, start a new empty one
jj new <change>        # branch new work from a specific change
jj new -m "message"    # new change with a message
jj edit <change-id>    # working copy becomes that change; edit it in place
jj edit @-             # edit the parent
jj edit @              # jump back to the working-copy change
```

`jj edit` on an immutable change — trunk, a tag, or a remote bookmark the repo does not track — is refused by default (see [Immutable Changes](#immutable-changes)). To fix published history, create a follow-up: `jj new <change>`.

### Describing

```bash
jj desc -m "message"                # set/update description of @
jj desc -r <change-id> -m "message" # any change
jj commit -m "message"              # shorthand: describe @ + start a new change
```

Descriptions support git-style bodies: title line, blank line, then a detailed spec or body.

### Squashing

Move changes from the current change into its parent:

```bash
jj squash -u          # all of @ into parent; preserve destination message
jj squash -r <id> -u  # squash a specific change; preserve destination message
```

Do not use `jj squash -i` (interactive; hangs). If both source and destination have descriptions, a full squash may invoke a message editor: use `-u` to preserve the destination description or `-m` to provide the resulting description explicitly.

### Splitting — choose the smallest necessary tool

For edits that fall into **entire files**, native jj is sufficient:

```bash
jj split -m "Extract validation" src/validation.rs
jj split -r <change-id> -m "Extract validation" src/validation.rs
```

This selects the named files into the **first (parent) change**; unselected edits remain in the original change (now the child). `-m` avoids description-editor prompts. Bare `jj split` invokes an interactive diff editor. **Do not use `jj restore` as a substitute for splitting**: restore discards/replaces content, it doesn't safely preserve both logical halves.

### Partial-file split / targeted squash (`jj-hunk-tool`)

When separate logical edits touch the **same file**, use [`mvzink/jj-hunk-tool`](https://github.com/mvzink/jj-hunk-tool) if installed. It operates through jj's history editing machinery, so ordinary jj recovery applies. Keep using native jj for whole-file operations.

```bash
# Discover hunks of the source revision. IDs and per-hunk line numbers come from here.
jj-hunk-tool hunks -r @ --compact
jj-hunk-tool hunks -r <change-id> --file src/validation.rs

# Preview the exact edit before moving it.
jj-hunk-tool patch <hunk-id> -r @

# Extract selected edits into an earlier change; the remainder stays in the source.
jj-hunk-tool split <hunk-id> -r @ -m "Extract validation"

# For inseparable adjacent edits, select lines WITHIN a hunk (not file line numbers).
jj-hunk-tool split <hunk-id>:1-3,7-9 -r @ -m "Extract validation"

# Move specific edits into an existing, possibly non-adjacent, mutable change.
jj-hunk-tool squash <hunk-id> --from @ --into <target-change-id> -u
```

**Selection and verification contract:**

1. Identify the source revision and intended destination. Read the full source diff and `hunks` output, then `patch` the *exact selection*. Do not guess hunk IDs, assume line numbers are file-relative, or indiscriminately select every hunk.
2. Run one targeted mutation, then inspect **both** sides using `jj --no-pager diff --git -r <source-change-id>` and `jj --no-pager diff --git -r <selected-or-target-change-id>`, plus `jj --no-pager log` / `jj st`. Confirm selected edits moved, unrelated edits stayed, and no unexpected conflicts or empty changes appeared.
3. After any edit or history rewrite, refresh `hunks` before another selection: IDs are content-based but do not authorize stale assumptions. If a selection fails, re-inspect rather than retrying blindly or falling back to destructive `restore`.
4. Do not use `jj-hunk-tool diffedit` for mixed binary/rename-bearing revisions without a verified fix: older revisions could silently drop such changes. CRLF may also cause patch failures. Prefer native file-level operations or defer uncertain selections rather than forcing a risky edit.
5. For concurrent editing of the **same workspace/revision**, coordinate or isolate first; a jj command may snapshot the working copy. A clean sidecar workspace is useful for rewriting someone else's active stack, but is unnecessary for ordinary serial work. Avoid rewriting a change currently checked out as another workspace's `@`.

If `jj-hunk-tool` is unavailable, do not invoke it or attempt `jj split -i`: use the native file-level split if possible, otherwise report that finer selection needs the tool. `jj-hunk-tool absorb --dry-run` can preview hunk-based ancestor routing, but prefer native `jj absorb` unless the hunk-level routing is specifically needed; validate destinations before applying.

### Absorbing

```bash
jj absorb   # distribute @'s changes to the ancestor commits that last touched those lines
```

### Restoring (discarding / moving changes)

```bash
jj restore                     # discard all uncommitted changes in @ (restore from parent)
jj restore path/to/file.txt    # discard changes to specific files
jj restore --from <id> path    # restore files from another change
```

### Abandoning — what it actually does

`jj abandon` removes a change and **rebases its descendants onto its parent(s)**. It does NOT fold the change's modifications into its parent. Abandoning the working-copy change leaves you a new, empty working-copy change. Treat `jj abandon` as discarding that change's work (recoverable via `jj undo` if needed, but not "absorbed into parent").

```bash
jj abandon <change-id>   # discard the change; descendants rebase onto its parents
jj abandon               # discard @ (you get a new empty @)
```

### Undo and recovery

```bash
jj undo               # reverse the last jj operation — any operation
jj --no-pager op log  # operation history, to find an earlier state
jj op restore <op-id> # restore the repo to any previous operation state
```

`jj undo` is usually simpler than manually reversing a mistake (accidental abandon, squash, or rebase). In a shared repository, verify that the latest operation is **yours** before undoing; otherwise inspect `jj op log` and coordinate recovery. Operation IDs support unambiguous prefixes.

## Bookmarks & Pushing

Bookmarks are jj's branches; remote git branches map to bookmarks on fetch. **Bookmarks do NOT auto-advance when you create new commits** — you must move them explicitly.

```bash
jj bookmark create my-feature -r @   # create a bookmark at a change
jj bookmark move my-feature --to @   # move an existing bookmark
jj --no-pager bookmark list
jj bookmark track main@origin        # follow a remote branch (jj hints when needed)
jj bookmark delete my-feature
```

**Push only when the user explicitly asks.** When pushing:

```bash
jj bookmark move my-feature --to @   # bookmarks don't auto-advance — move it first
jj git push --bookmark my-feature    # push one bookmark
jj git push                          # push all changed bookmarks
jj git push --deleted                # after abandoning a pushed change, sync the deletion
```

Before pushing, ensure: the bookmark points at the correct change, the commits are refined and atomic, and the user has explicitly requested the push.

## Immutable Changes

`immutable()` is `::(immutable_heads() | root())`: every ancestor of an immutable head is frozen, and rewriting one (`jj edit`, `jj desc`, `jj squash`, `jj rebase`) is refused. The builtin definition is `trunk() | tags() | untracked_remote_bookmarks() | untracked_remote_tags()`.

Two consequences of that default decide ordinary work:

- **A tracked remote bookmark is mutable.** Pushing your own branch does not freeze it, so refining it and pushing again is normal.
- **An untracked remote bookmark is immutable** — a branch pushed from another machine, or one whose local bookmark you deleted. `jj bookmark track <name>@<remote>` is the fix that follows from the model.

Identify the head before reaching for `--ignore-immutable`, which unblocks one rewrite rather than fixing a branch you keep rewriting:

```bash
jj config list --include-defaults | grep immutable   # what this repo freezes
jj --no-pager log -r 'immutable_heads()'             # the heads doing the freezing
jj --no-pager log -r '<rev> & immutable()'           # is this change under one?
```

### Carving out a branch

A repo may redefine `immutable_heads()`. The nix dotfiles repo carves out `wip/*` so a wip branch stays rewritable while trunk and tags keep their protection:

```toml
[revset-aliases]
"immutable_heads()" = "trunk() | tags() | untracked_remote_tags() | (untracked_remote_bookmarks() ~ remote_bookmarks('wip/*'))"
```

Read the definition in force before reasoning from the builtin, and treat the repo's policy as the policy: a refused rewrite is the signal to inspect what froze it, not to unlock it.

Writing such an override:

- `remote_bookmarks([name_pattern], [[remote=]remote_pattern])` takes positional arguments; `remote_bookmarks(pattern='wip/')` fails with `Unexpected keyword argument`.
- A bare string is not a prefix — `'wip/'` matches nothing, `'wip/*'` matches `wip/scratch`.
- The alias replaces the builtin outright, so keep `trunk()`, `tags()`, and `untracked_remote_tags()` unless the repo means to unlock them.
- `remote_bookmarks()` on the left instead of `untracked_remote_bookmarks()` also freezes your own pushed branches, which then need `--ignore-immutable` to amend.

## Git Bridge

### Fetching and rebasing onto trunk

```bash
jj git fetch                   # fetch all branches from the default remote
jj git fetch --remote <name>   # fetch a specific remote
jj git fetch -b <branch>       # fetch specific branches
jj rebase -d main              # rebase current branch onto the updated trunk
```

### Mixing jj and git (colocated repos only)

In a **colocated** repo (`.jj/` and `.git/` both present), jj imports/exports Git on every command, and mixing `jj` and `git` commands is supported — git mutations are detected and incorporated on the next jj command. In a **non-colocated** repo, do NOT use git commands against it.

For an agent, the safe default is: use `jj` for all mutations, and read-only git (`git log`, `git diff`, `git status`) when convenient. Interleaving git and jj mutations is legal but confusing — avoid it.

## Workspaces & Parallel Agents

A workspace is a working copy plus its associated repo. One repo can have several workspaces — each with its own directory and its own `@` — all sharing the same commits, operations, and bookmarks. This is jj's equivalent of `git worktree`, and the mechanism for parallel agents.

```bash
jj workspace add ../ws-other        # new workspace with its own fresh empty @
jj workspace add --name agent2 -r <change-id> ../ws-2   # explicit name and base
jj --no-pager workspace list
jj workspace forget <name>          # forget the workspace (does NOT delete files on disk)
jj workspace rename <name>
jj workspace update-stale           # fix a stale working copy (see below)
```

In `jj log`, each workspace's `@` appears as `<name>@`.

### Key semantics

- **Isolation by default.** New workspaces get their own empty change; on-disk files are never live-mirrored between workspaces.
- **Propagation at command boundaries.** Each jj command snapshots files and reads the op log, so it sees commits/bookmarks made by other workspaces. There is no filesystem watcher.
- **Stale working copy.** If another workspace rewrote your `@` (e.g. via `squash`, `rebase`, or `abandon`), jj refuses commands here until you run `jj workspace update-stale`. Same recovery path after an interrupted update.
- **Never share `@` across workspaces.** Two workspaces pointing at the same change is the main cause of divergence: when one mutates it, the other goes stale, and if the stale one had un-snapshotted edits, `update-stale` preserves them as a **divergent commit** (same Change ID, shown `xyz??` in `jj log`) that must be resolved manually. Don't `jj edit` a change another workspace has as its `@`.

### Parallel-agent workflow

Multiple agents work in separate workspaces from the same base, then an integrator merges the results:

```bash
# agent A, workspace ws-a
jj new main && jj desc -m "feat: part a"
# agent B, workspace ws-b
jj new main && jj desc -m "feat: part b"
# integrator, later:
jj new ws-a@ ws-b@ -m "merge a and b"   # merge two changes
jj new <change1> <change2> ...          # general merge
```

## Agent Workflow Patterns

### Start next task

```bash
jj new
jj desc -m "feat: implement avatar upload"
# ... code ...
```

### Interrupt and resume

Handle an urgent task mid-work without stashing or branch switching:

```bash
jj new main                # branch off main for the urgent fix
# ... do the fix ...
jj desc -m "fix: critical auth bug"
jj edit <previous-change>  # jump back; resume where you were
```

### Skeleton planning (complex tasks)

Create empty changes as a plan, then fill them in order:

```bash
jj new -m "refactor: extract auth module"
jj new -m "feat: add token refresh logic"
jj new -m "test: update auth tests"
```

Then `jj edit <first-change>`, implement, `jj edit <next-change>`, and so on. Descendants auto-rebase as you fill ancestors, so you never manually rebase. Each change's description doubles as its acceptance criteria — verify your implementation matches it before moving on.

### Recover from a mistake

```bash
jj undo                  # undo the last operation
jj --no-pager op log     # look further back
jj op restore <op-id>    # restore any previous state
```

## Conflicts

jj allows committing conflicts and resolving them later:

```bash
jj st   # shows conflicts
```

**Resolve conflicts by editing the conflicted files directly** (remove markers, pick content), then run `jj st` to verify resolution. Do not use `jj resolve` — it opens an interactive tool and hangs an agent.

## Template & Revset Gotchas

Templates (`-T`) use jj's own expression language — not JavaScript, not shell interpolation.

- **String concatenation requires `concat()`** — there is no implicit joining:

  ```bash
  # wrong: jj log -r @ -T 'commit_id.short() description'
  jj --no-pager log -r @ -T 'concat(change_id.short(), " | ", description)'
  ```

- **The field is `description`, not `desc`** (e.g. `jj log -T 'description'`).
- **Quote revsets containing `|`** (single or double shell quotes work), so the shell does not treat the pipe as a command operator:

  ```bash
  jj --no-pager log -r "id1 | id2" -T 'concat(change_id.short(), "\n", description)'
  ```

- **After `jj desc -r <id>`, don't verify with `@`** — `@` is the working-copy change and may not be the change you just edited. Verify with the explicit change ID.

## Common Mistakes

- Using `git add`, `git commit`, `git stash`, or `git checkout` in a jj repo — use the jj equivalents.
- Running bare `jj split`, `jj squash -i`, `jj diffedit`, `jj-hunk-tool absorb -i`, or `jj resolve` — interactive; hangs the agent.
- Forgetting `--no-pager` on `jj log` / `jj diff` / `jj show`.
- Assuming bookmarks auto-advance — they don't; move them before pushing.
- Reading a refused rewrite as a reason for `--ignore-immutable` — track the remote bookmark instead, or work from a follow-up change.
- Thinking `jj abandon` folds changes into the parent — it discards and rebases descendants.
- Sharing `@` between two workspaces.
- Creating bookmarks for local-only work — bookmarks are only for pushing.
- Forcing upfront atomic changes or over-refining trivial edits; when refinement is useful, split/squash/absorb intentionally and verify its effect.

## Commit Quality Checklist

Before considering work done:

1. Review: `jj --no-pager show @` or `jj --no-pager diff --git`.
2. Is it atomic? One logical change per commit.
3. Is the message clear? Imperative verb phrase in sentence case, no trailing period — e.g. "Add login endpoint", "Fix null pointer in payment processor", "Remove deprecated API endpoints".
4. Unrelated changes worth separating? `jj split` by file or `jj-hunk-tool split` by hunk/lines; do **not** discard them with `jj restore`. Avoid gratuitous micro-changes.
5. Changes belong elsewhere? Native `jj squash`/`jj absorb`, or targeted `jj-hunk-tool squash` for partial-file edits. Verify source, destination, and remaining diffs.

## Quick Reference

| Action | Command |
|--------|---------|
| Detect jj repo | `test -d .jj && echo jj` |
| Init in git repo | `jj git init --colocate` |
| View status | `jj st` |
| View log | `jj --no-pager log` |
| View diff | `jj --no-pager diff --git` |
| Describe | `jj desc -m "message"` |
| Start new change | `jj new -m "message"` |
| Edit a change | `jj edit <change-id>` |
| Squash into parent | `jj squash -u` (keep destination message) |
| Split whole files | `jj split -m "message" <filesets>` |
| Inspect hunks | `jj-hunk-tool hunks -r @ --compact` |
| Preview chosen hunks | `jj-hunk-tool patch <hunk-id> -r @` |
| Split selected hunk/lines | `jj-hunk-tool split <hunk-id> -r @ -m "message"` |
| Move hunk into existing change | `jj-hunk-tool squash <hunk-id> --from @ --into <change-id>` |
| Auto-distribute | `jj absorb` |
| Discard a change | `jj abandon <change-id>` |
| Undo last operation | `jj undo` |
| Operation history | `jj --no-pager op log` |
| Restore repo state | `jj op restore <op-id>` |
| Discard file changes | `jj restore <path>` |
| Create bookmark | `jj bookmark create <name> -r @` |
| Move bookmark | `jj bookmark move <name> --to @` |
| Track remote bookmark | `jj bookmark track <name>@<remote>` |
| See what is immutable | `jj --no-pager log -r 'immutable_heads()'` |
| Fetch remote | `jj git fetch` |
| Rebase onto trunk | `jj rebase -d main` |
| Push bookmark | `jj git push --bookmark <name>` |
| Push bookmark deletions | `jj git push --deleted` |
| New workspace | `jj workspace add <path>` |
| Fix stale working copy | `jj workspace update-stale` |
| Forget workspace | `jj workspace forget <name>` |
| Merge changes | `jj new <change1> <change2> -m "merge"` |
