# Env templates per shell dialect

## Why the shared agent-env template is rendered once per shell

**Id:** e7014299-af11-469b-8db4-12862b1e69eb
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** measurement on legion — the nixpkgs bash's `compgen` availability, and a fish session sampled before and after the `replay` call
**Verification:** corroborated — the generated fish config sources `agent-env.fish` with no `replay` call left, both templates render the same nine keys, and a fish session sourcing a file of that shape exports its variables (`env` lists them)
**Revisit when:** a third shell needs the env-only keys, or a key's value can contain whitespace, which would make both dialects need quoting

Fish cannot source a `KEY=value` file, so `modules/shell/fish.nix` read the POSIX
`agent-env.env` through `replay`, a fish plugin that runs its argument in a bash
subshell and replays the resulting environment back into the session. Borrowing
bash looked like the way to read one file from both shells.

Replay re-imports the whole environment, and then erases every exported variable
the subshell did not report:

```fish
for name in (set --export --names)
    contains -- $name $env || echo "set --erase $name"
end
```

That comparison list comes from `compgen -e`. The bash nixpkgs ships
(5.3.15 — the one a dev shell puts first on `PATH`) does not provide `compgen`,
so the list is empty and the erase loop removes everything. In a fish session
with 215 exported variables, `replay "set -a; source …; set +a"` left 3: `PATH`,
`HOME` and all nine keys it was called to load were gone, with two stderr lines
about read-only `PWD` and `SHLVL` as the only sign. Direnv loads the dev shell
inside this repository, which is exactly where the shell is used.

The shared key list now lives once in `modules/security/credentials.nix` and
renders into two templates: `agent-env.env` for POSIX shells (sourced by zsh
under `set -a`) and `agent-env.fish` (`set -gx`, sourced directly by fish). No
subprocess, no parser, no whole-environment round trip.

**Reason:** a shell that cannot read a file's syntax should not be handed a
subprocess that rewrites its environment in order to get at it.

**Rejected alternative:** keep the single agnostic file and parse it in fish
(`string split -m1 = -- $line`), which leaves one secret artifact on disk
instead of two. Rejected because it puts a parser in shell init where a rendered
line of data does the job, and because rendering per dialect is what Home
Manager already does for its own session variables.

**Consequence:** the env-only keys exist as two 0400 files in the same rendered
directory; adding a key means adding it to the one list, which renders both.
`replay` stays installed for imperative use — it is only unsafe where it is
handed a shell's entire environment at startup.
