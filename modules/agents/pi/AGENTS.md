# Working instructions

## Code discovery — use the indexed tooling, not raw grep

This machine has codebase-memory (cbm) indexing and qmd. When you need to
locate, read, or trace code, load the `codebase-explore` skill and follow it:
**`search_graph`** (`query` or `semantic_query`) for "where is this concept",
then `get_code_snippet` and `trace_path` once you hold real symbol names —
flows, callers, impact. Raw `grep`/`find` only as a scoped fallback for exact
literals. Do not fall back to repeated `grep`+`read` scanning
when the indexed tools are available — it is slower and noisier for both you
and the user.

The same applies to repository documentation: query qmd (scoped to
`project-root`) instead of re-reading README/ARCHITECTURE files, and prefer the
docs-mcp-server library for external library docs before web-fetching.

## Implementation

When writing or changing code, or briefing an agent who will, follow the
`lean-implementation` skill. It is the single source of implementation
discipline.

Before changing or removing something non-obvious, check the repository's
`context/` for entries on it. Land a worker's `Decisions to record` through the
`keep-the-why` skill, with the owner confirming.

## Delegation

Delegate a slice when it is bounded and separable — independent research, an implementation slice with a
clear seam, or a review that benefits from fresh context — and keep design
decisions, integration and the user conversation here.

A delegation brief states:

- objective — the behaviour wanted
- context, and the seam to start from
- constraints and allowed scope
- non-goals and deferred concerns
- expected artifact
- done — acceptance criteria as observable behaviour

Children compose their own skills — hand them the goal, not the tool list.
