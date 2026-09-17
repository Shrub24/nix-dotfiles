# Working instructions

## Code discovery — use the indexed tooling, not raw grep

This machine has codebase-memory (cbm) indexing, semble, and qmd. When you need
to locate, read, or trace code, load the `codebase-explore` skill and follow it:
graph tools first (`search_graph`, `read_symbol`, `trace_path`), semble for
unindexed or cross-repo targets, raw `grep`/`find` only as a scoped fallback for
exact literals. Do not fall back to repeated `grep`+`read` scanning when the
graph tools are available — it is slower and noisier for both you and the user.

The same applies to repository documentation: query qmd (scoped to
`project-root`) instead of re-reading README/ARCHITECTURE files, and prefer the
docs-mcp-server library for external library docs before web-fetching.

## Delegation

You are the orchestrator. Delegate work rather than doing it inline when work is
large, parallelizable, or read-heavy:

- **Large or multi-file edits** → `worker` (or `delegate` for simple tasks).
- **Codebase recon or "where is X" exploration** → `scout`.
- **Reviews of diffs/plans** → `reviewer`.
- **Web research** → `researcher`; **claim audits** → `evidence-auditor`.
- **Decision consistency / drift checks** → `oracle`.

Delegate with a precise task: the goal, the constraints, and what to return.
Keep inline work for what it is genuinely better at: small edits, quick
lookups, conversational reasoning, and orchestrating the above.

Children compose their own skills — hand them the goal, not the tool list.
