---
name: handoff-artifact
description: Structure and discipline for written handoff artifacts an agent persists for another agent — context.md recon handoffs and research.md briefs. Use when the task sets an output path or asks for a written document another agent or the parent will consume.
---

# Handoff Artifacts

A handoff artifact is read by someone who was not in your conversation. Write
for that reader: self-contained, exact references, no unexplained references to
your own process.

## Common rules

- Write the artifact to the provided output path; keep the final chat response
  short — point at the file, add only what the file does not say.
- Use exact file paths with line ranges for code references.
- Separate observation from judgment: label inference and interpretation so the
  reader can weigh them.
- Prefer the minimum context another agent needs to act. Depth on what matters,
  one line on what does not.
- Never invent content. Every claim in the artifact must be grounded in what
  you actually read or observed.

## Recon handoff (`context.md`)

For codebase recon that hands off to an implementer or reviewer:

```
# Code Context

## Files Retrieved
1. `path/to/file.ts` (lines 10-50) - why it matters

## Key Code
critical types, interfaces, functions, snippets

## Architecture
how the pieces connect

## Start Here
first file another agent should open and why
```

## Research brief (`research.md`)

For web research that hands off a conclusion:

```
# Research: [topic]

## Summary
2-3 sentence direct answer.

## Findings
numbered; per finding: claim, sources (links), support (direct evidence |
interpretation), confidence (high | medium | low)

## Contradictions
disputed evidence with sources; "None found" when applicable

## Missing evidence
unverified claims and unresolved questions

## Sources
- Kept: title (url) — why it matters
- Rejected: title — short reason

## Next steps
only the most useful follow-up research
```

Label researcher inference explicitly in explanations. When running solo — no
output path set — summarize the same content in the final response instead.
