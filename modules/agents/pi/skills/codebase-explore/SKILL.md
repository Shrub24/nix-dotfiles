---
name: codebase-explore
description: Grounded codebase investigation for agents — semble first for semantic "where is this concept" discovery, codebase-memory graph tools to narrow structure (flows, callers, impact), search_code/grep for exact literals, qmd for repo docs. Use whenever a task requires locating, reading, or tracing code.
---

# Codebase Exploration

Two indexed layers, two jobs: **semble finds where a concept lives** (semantic,
no index prerequisite, cross-repo); **codebase-memory narrows how it connects**
(callers, flows, impact, exact symbols). Filesystem tools fill gaps only.

## Discovery order

1. **Semble — semantic entry point.** For the first question ("where is
   authentication handled?", "what implements this interface?"), describe the
   behavior or name the symbol. One focused search, navigate to the returned
   file:line, do not repeat the search.
1. **Graph tools — structural narrowing.** Once you hold real symbol names,
   switch to codebase-memory: trace flows, callers/callees, impact, dead code,
   and read exact snippets (see routing below). This is where "narrow down the
   flow" work belongs.
1. **Exact literals** (env vars, config keys, route strings, error text,
   comments) → `search_code` or `grep`, never the graph — the graph indexes
   symbols, not strings.
1. **qmd** for repository documentation (see below).

## Semble usage (semantic search + related-code)

```bash
semble search "authentication flow" ./my-project --max-snippet-lines 10  # concise
semble search "save_pretrained" ./my-project                          # full chunk
semble search "save model to disk" ./my-project --top-k 10            # more results
```

The index builds on first run, is cached, and invalidates automatically when
files change. In pi sessions the same capability is exposed as MCP tools
(`semble_search`, `semble_find_related`) — prefer those when loaded; the CLI
works everywhere.

- `--content docs` searches documentation and prose, `--content config`
  covers yaml/toml config, `--content all` spans code + docs + config:
  ```bash
  semble search "deployment guide" ./my-project --content docs
  semble search "database host port" ./my-project --content config
  semble search "authentication" ./my-project --content all
  ```
- `find-related` discovers code similar to a known location (pass
  `file_path` + `line` from a prior result) — all implementations of an
  interface, all callers, sibling tests:
  ```bash
  semble find-related src/auth.py 42 ./my-project
  ```
- `path` defaults to cwd; git URLs are accepted. Pass several paths/URLs to
  search related repos together (e.g. this repo calls a service defined in a
  sibling repo) — results get repo-name prefixes plus a `repos` map:
  ```bash
  semble search "invoice endpoint" ./service-a ../service-b
  ```
- Write queries as function/class names or behavior descriptions, never
  error-message text.

## Graph tool routing (codebase-memory)

- Known symbol → `resolve_symbol` to disambiguate, then `get_code_snippet` with
  the resolved qualified name (or `search_and_read_symbols` with disambiguators
  `file_path`, `parent_class`, `label`). Disambiguation fails closed on
  ambiguity; retry with more disambiguators rather than guessing.
- Structural questions on known symbols → `get_code_snippet` with
  `include_neighbors` for direct callers/callees; `trace_path` (depth 2-3) for
  multi-hop workflow, dependency, or data-flow questions.
- Unfamiliar repo orientation → `get_architecture`. Custom graph questions →
  `get_graph_schema` before `query_graph`; keep columns narrow, rows few.
  Deep graph work (edge types, Cypher for `query_graph`, tool gotchas) → read
  the official `codebase-memory` skill at
  `~/.agents/skills/codebase-memory/SKILL.md`.
- Dead code / fan-out audits → `search_graph(max_degree=0, exclude_entry_points=true)` / `min_degree` filters.
- Evidence discipline: fast positive lookups (Scout tier) are provisional —
  never claim absence, exhaustiveness, or complete impact from them. Before
  delegating or making material claims, run `check_index_coverage` once with
  every evidence path; read/grep any reported missed ranges before relying on
  the graph. Negative or exhaustive claims require Verify/Auditor-tier
  discipline (task-directed searches, exact snippets, both trace directions).

## Reading discipline

- Graph results are compact and location-first; do not request
  `include_metadata` unless raw metrics are needed.
- If a symbol's source comes back compacted, retry with a higher
  `max_symbol_lines` or `full_output=true` before falling back to raw file reads.
- Prefer targeted search plus selective reading over whole-file reads. When you
  cite code, use exact file paths and line ranges.

## Scope-first search

Start from task-provided paths, symbols, and seams. Use `find` for path
discovery. Reserve unscoped `grep` for exhaustive exact-literal verification
after a scoped source/path pass — checking call sites, imports, removed names,
or absence of a pattern.

## Repository documentation (qmd)

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
