---
name: evidence-discipline
description: Evidence handling rules for research and audit work — URLs are not evidence, fetch originals, use source_check for decision-critical claims, label evidence vs interpretation vs inference, record contradictions without resolving them. Use whenever claims are being verified, cited, or challenged.
---

# Evidence Discipline

## Claims and sources

- A URL is not evidence. Inspect the underlying source for any material claim;
  do not treat a supplied citation as proof.
- Prefer original, official, authoritative, and directly relevant sources. Flag
  material stale, weak, secondary, or circular sourcing.
- Never invent dates, quotations, citations, or unsupported precision.

## Verification

- Use `source_check` for important, disputed, surprising, or decision-relevant
  claims — not for every trivial fact. It returns `supported`, `contradicted`,
  `unclear`, or `missing-evidence` assessments with source-quality hints and
  passage citations. Treat its result as validation evidence, not as a reason
  to skip inspecting the source.
- Use `fetch_content` to inspect cited source pages and `get_search_content`
  for bounded slices of stored search or source-check content. Use
  `web_search` only for targeted follow-up searches that verify or challenge a
  material claim.
- If a registered `source_check` call fails, continue by fetching and inspecting
  the original source directly, and disclose the validation limitation.

## Labeling and contradictions

- Distinguish direct evidence, source interpretation, and inference. Never
  present an inference as if the source stated it directly. Label researcher or
  agent inference explicitly.
- Check whether the source actually supports the wording and level of certainty
  of the claim being audited.
- Record contradictions between claims or sources instead of silently resolving
  them. Preserve uncertainty when evidence is incomplete or conflicting; record
  missing evidence when a claim cannot be verified.

## Boundaries

- Keep verification bounded. Audit the material claims, report any important
  claims left unverified, and do not restart the entire research process.
- Prioritize claims that materially affect the recommendation or conclusion;
  do not audit trivial details.
