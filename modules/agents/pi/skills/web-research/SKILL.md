---
name: web-research
description: Web research and source-hunting workflow over the installed web tools — web_search/fetch_content/get_search_content/source_check, plus gh CLI for GitHub data and optional extended sources when present. Use for any task that searches the web, fetches pages, or researches documentation.
---

# Web Research

## Before searching: check what we already know

Prior sessions likely settled parts of the question. Check before crawling:

- **cass** — search/pack over past coding-agent conversations:
  `cass search "query" --robot` to explore, `cass pack "query" --robot` for a
  bounded, cited handoff artifact of what prior sessions established. Ideal
  for tool quirks, benchmark numbers, and decisions made before.
- **project memory** — `ctx_search` for durable project facts and decisions;
  `source: memory` for curated knowledge, omit for full history including raw
  messages.

Research that starts from prior art avoids re-deriving settled facts.

## Core tools (always available)

- **`web_search`**: run `{queries: [...]}` with 2-4 varied angles — different
  phrasing, scope, and intent per query — instead of one generic query. Each
  query gets its own synthesized answer, so varying them widens coverage. Use
  `workflow: "none"` unless the interactive curator is explicitly needed. Set
  `includeContent: true` when you will need page text anyway.
- **`fetch_content`**: fetch the original page when a claim matters. Handles
  GitHub repos, PDFs, YouTube (yt-dlp), local videos, and direct image URLs.
  Use `mode: "raw"` for exact response bodies, `mode: "answer"` to answer a
  question from one page, `timestamp`/`frames` for video moments.
- **`get_search_content`**: retrieve bounded slices of stored search or fetch
  results — use `findText` to locate passages without paging, `offset`/`limit`
  for slices. Cheaper than re-fetching.
- **`source_check`**: verify claims against fetched content (see
  evidence-discipline for its treatment).

## GitHub data

Use the `gh` CLI for repository, issue, PR, and code data — it is faster and
more precise than scraping:

- `gh search code 'pattern' --repo owner/repo` — literal code search
- `gh api repos/{owner}/{repo}/...` — structured data
- `gh pr view`, `gh issue list` — state and discussion

## Extended sources (use if available, fall back to core if not)

Some environments expose additional research channels. If present, prefer them
for their niche; if absent, proceed with the core tools — never treat a missing
extended source as a blocker.

- **grep.app MCP** (`mcp.grep.app`, `searchGitHub`): literal code-pattern search
  across a million public repos. Best for "how do real projects use this API".
- **sourcegraph** (CLI or web): repo semantic/structural search at scale —
  think a heavier semble over unindexed repos; use when semble is absent or
  the question spans many repos.
- **docs-mcp-server**: versioned local semantic doc search for important
  libraries; ingest-on-first-contact (see codebase-explore). Prefer it over
  web fetching for library questions.

## Workflow

1. Decompose into 2-4 distinct research angles.
1. Search per angle with `queries`; treat summaries as discovery aids only.
1. Fetch originals for anything decision-relevant, disputed, surprising, or
   material.
1. Keep a smaller set of strong sources rather than many weak or redundant
   ones; reject stale, redundant, or SEO-heavy sources.
1. Verify decision-critical claims with `source_check`.
1. Stay bounded: one tighter follow-up pass for remaining gaps, then report
   remaining uncertainty and stop.
