# qmd

## The CLI and the service come from one Nix build

**Id:** 4b74f0ad-70ba-40bf-bf7a-637a54964f16
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** the llm-agents.nix build changes its packaging, or qmd gains a trust mode the user service can approve without a terminal

`programs.qmd` puts `cfg.package` in `home.packages` whenever it is enabled, so the
`qmd` on PATH is the same patched build that the `qmd` user service runs.

**Reason:** the module created the service only, and once the Arch-era pnpm copy was
removed no CLI existed. That pnpm copy also tried to compile llama.cpp from source and
failed; the Nix build already carries the glibc, writable-path and `LD_LIBRARY_PATH`
patches and runs its embeddings on the GPU through Vulkan, so it needs no CUDA wiring and
no `nix-ld`.

**Trust:** the repo-local, gitignored `.qmd/` config points at paths outside the project
and a custom embed model, which qmd skips until approved. Running `qmd trust` from the
repository once approves it; the service uses the global `~/.config/qmd` and needs
nothing. The `specs` collection (`openspec/specs` only) lives in that local config, so it
is visible only when `qmd` runs inside the repository.
