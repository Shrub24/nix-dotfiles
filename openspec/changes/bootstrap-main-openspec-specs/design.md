## Context

This repo uses a spec-driven OpenSpec workflow, but the main `openspec/specs/` directory is empty. Completed changes such as `add-system-manager`, `migrate-tokf-to-snip`, `tmux-ssh-mutagen-modules`, and archived `migrate-bifrost-to-litellm` already describe active capabilities, yet that knowledge only lives inside per-change delta specs.

Without a canonical main-spec registry, future proposals cannot reliably tell whether they are introducing a new capability or modifying an existing one. The immediate need is to bootstrap main specs from completed changes whose results are currently active in the repo.

## Goals / Non-Goals

**Goals:**
- Create canonical main specs in `openspec/specs/` for active capabilities from completed changes.
- Preserve provenance by recording which change introduced each canonical spec.
- Add a lightweight index so maintainers can discover existing canonical specs quickly.
- Avoid syncing unfinished or inactive changes into the main spec registry.

**Non-Goals:**
- Rewriting completed change specs from scratch.
- Syncing unfinished changes such as `agentmemory` or partially complete changes such as `hermes-agent`.
- Changing runtime code or Home Manager behavior beyond OpenSpec artifact management.

## Decisions

### D1. Bootstrap from completed change specs instead of inventing new main-spec text
Completed change specs already capture reviewed capability behavior. The main registry should be derived from them with only minimal normalization.

**Alternatives considered:**
- Rewrite all main specs manually from implementation state.
- Leave main specs empty and rely on archived changes forever.

### D2. Keep one canonical spec file per capability under `openspec/specs/<capability>/spec.md`
This mirrors the existing change-scoped spec layout and keeps the mental model consistent between delta specs and main specs.

**Alternatives considered:**
- Flat files directly under `openspec/specs/`.
- A single monolithic spec registry document.

### D3. Only sync capabilities from completed changes whose delivered behavior is still active
Archived changes can still be the source of active capabilities, while incomplete changes must not be treated as canonical truth.

**Alternatives considered:**
- Sync every change regardless of status.
- Sync only archived changes.

### D4. Track provenance and lifecycle in the canonical spec files and index
Each canonical spec should identify its source change and current lifecycle status so later changes can supersede behavior without losing history.

**Alternatives considered:**
- Keep provenance only in an index file.
- Omit lifecycle metadata and rely on git history.

## Risks / Trade-offs

- **Capability drift between delta and canonical specs** → Copy from completed deltas as directly as possible and keep provenance explicit.
- **Syncing the wrong changes** → Restrict bootstrap scope to completed changes with active delivered behavior.
- **Future collisions between capabilities** → Use one directory per capability and make provenance visible in the index.

## Migration Plan

1. Inventory completed changes and enumerate their active capability specs.
2. Create canonical capability specs under `openspec/specs/` with provenance metadata.
3. Add an `openspec/specs/INDEX.md` file listing capability name, status, and source change.
4. Validate the new change strictly and keep bootstrap tasks checked as each step completes.

## Open Questions

- Whether a later follow-up should automate delta-to-main spec sync instead of relying on manual bootstrap and future maintenance.
