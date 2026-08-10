## Why

The repo currently ships a custom `tokf` package for agent-oriented shell output filtering, but upstream `snip` now offers a more broadly maintained filter engine plus a dedicated OpenCode plugin. Replacing `tokf` with `snip` reduces local maintenance burden, aligns the toolchain with the current OpenCode workflow, and makes the integration easier to document and evolve.

## What Changes

- **New package**: `pkgs/snip` — package upstream `edouard-claude/snip` as a pinned Nix derivation
- **Agent tools migration**: replace `tokf` with `snip` in the Home Manager agent tools bundle
- **OpenCode integration**: add `opencode-snip` to the imperative OpenCode plugin list so shell commands can be filtered transparently
- **Cleanup**: remove the local `pkgs/tokf` derivation and update architecture/structure docs to reflect the new tool

## Capabilities

### New Capabilities
- `snip-package`: Provide a pinned `snip` CLI derivation and install it through the agent tools package set
- `opencode-snip-integration`: Configure OpenCode to use the `opencode-snip` plugin when `snip` is present in PATH

### Modified Capabilities
- *(none — no existing spec capabilities are being modified)*

## Impact

| Area | Affected |
|------|----------|
| Packages | New: `pkgs/snip`; Removed: `pkgs/tokf` |
| Flake overlay | `flake.nix` package overlay entry |
| Home Manager | `modules/home/agents/tools.nix` agent tool bundle |
| OpenCode config | `apps/opencode/opencode.jsonc` plugin list |
| Documentation | `ARCHITECTURE.md`, `STRUCTURE.md` |
| Verification | Home Manager evaluation/build, OpenCode plugin wiring sanity |
