---
name: codebase-explore
description: Grounded codebase investigation order for agents with codebase-memory graph tools — search_graph/read_symbol/trace_path first, semble for unindexed or cross-repo semantic search, raw grep/find as fallback, qmd for repo docs. Use whenever a task requires locating, reading, or tracing code.
---

# Codebase Exploration

Run discovery through the indexed graph first; fall back to filesystem tools only
when the graph cannot answer. This order is cheaper and more precise than grepping.

## Discovery order

1. **Graph tools** (codebase-memory, symbol-aware, compact results) for the
   indexed working repo.
1. **Semantics on demand** — `semble_search` / `semble_find_related` for repos
   codebase-memory has not indexed, cross-repo questions, or "find all
   implementations of this interface" sweeps (see below).
1. **Filesystem tools** (`grep`/`find`/`ls`/`read`) when graph and semble
   cannot answer or the target is non-code text.
1. **qmd** for repository documentation (see below).

## Graph tool routing

- Known symbol → `resolve_symbol` to disambiguate, then `read_symbol` with
  disambiguators (`file_path`, `parent_class`, `label`). It fails closed on
  ambiguity; retry with more disambiguators rather than guessing.
- Conceptual or unknown target → `search_graph` with a small limit (5-12). Need
  source too → `search_and_read_symbols` with `read_limit` 3-8.
- Exact literals (env vars, config keys, route strings, error text, comments) →
  `search_code` or `grep`, never `search_graph`.
- Direct callers/callees → `read_symbol` with `neighbors`; multi-hop workflow,
  dependency, or data-flow questions → `trace_path`, depth 2-3.
- Unfamiliar repo orientation → `get_architecture`. Custom graph questions →
  `get_graph_schema` before `query_graph`; keep returned columns narrow and rows
  few.

## Reading discipline

- Results are compact and location-first; do not request `include_metadata`
  unless raw metrics are needed.
- If a symbol's source comes back compacted, retry with a higher
  `max_symbol_lines` or `full_output=true` before falling back to raw file reads.
- Prefer targeted search plus selective reading over whole-file reads. When you
  cite code, use exact file paths and line ranges.

## Scope-first search

Start from task-provided paths, symbols, and seams. Use `find` for path
discovery. Reserve unscoped `grep` for exhaustive exact-literal verification
after a scoped source/path pass — checking call sites, imports, removed names,
or absence of a pattern.

## Semble (semantic search without an index)

`semble_search` accepts a git URL or local path (indexes are cached per
session) — use it when the repo is not in codebase-memory, for quick questions
about a foreign repo, or as the fast lane a full sourcegraph setup would
serve. Write queries as function/class names or behavior descriptions, never
error-message text. One focused search; navigate to the returned file:line, do
not repeat the search.

`semble_find_related` takes `file_path` + `line` from a prior result and finds
similar code — all implementations of an interface, all callers, all tests for
a class.

## Repository documentation

For README/ARCHITECTURE/design-doc questions, query the qmd index scoped to the
`project-root` collection. Unscoped doc searches return same-named documents
from sibling projects and look authoritative while being stale or foreign.
Refresh the index when results appear stale.

## Versioned doc library (docs-mcp-server)

For important libraries and technologies the project depends on, use the
docs-mcp-server library rather than re-crawling the web each time:

- `search_docs` first — the library may already be indexed, versioned, and
  locally searchable with semantic results.
- If a new important dependency is not indexed, start an indexing job
  (`list_jobs`/`get_job_info` to manage it) so future sessions can search it
  locally instead of fetching pages repeatedly.
- Ingest-on-first-contact is the habit: every significant library or tech the
  work touches should end up in the doc library.
