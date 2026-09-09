---
name: review-policy
description: Severity ladder and finding discipline for code and plan reviews — P0/P1/P2 definitions, evidence-over-severity filtering, diff-causality, blockers-only usage, and merge verdicts. Use when reporting review findings or deciding a merge verdict.
---

# Review Policy

## Severity ladder

- **P0** — blocks merge. Broken behavior, data loss, security holes, contract
  violations the diff introduces.
- **P1** — should be fixed before release. Real issues that do not block the
  merge itself.
- **P2** — report-only notes. Style, minor cleanup, observations.

## Finding discipline

- Filter findings by evidence, not by severity. Report only concrete current
  issues within the named review target, each supported by source proof, a test
  or repro, or a contract contradiction.
- For a diff review, require that the issue is caused or made reachable by that
  diff. Pre-existing problems outside the target are not findings.
- Do not invent issues. If everything looks good, say so plainly — and say
  exactly `No issues found.` when nothing qualifies.
- Prefer small corrective edits over broad rewrites when fixes are in scope.

## Blockers-only mode

Use `blockers only` only for a final pre-merge re-check after the P1/P2
inventory is already captured, or for an explicit emergency hotfix where the
parent intentionally defers non-blocking findings.

## Verdicts

- **BLOCK** — any P0 outstanding.
- **OK** — no findings.
- **OK with notes** — P1/P2 recorded, nothing blocking.
