# Hermes agent pin

## hermes-agent is pinned to an unmerged upstream PR head

**Id:** 6046b69e-3dcb-4842-a68c-eb9d046e04ed
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** NousResearch/hermes-agent#141750 (issue) and #141834 (PR, head `68ce9ec9`); `modules/agents/hermes.nix`

The `hermes-agent` input is declared at `68ce9ec9`, the head of PR #141834, not at the default branch. Upstream reads `uv.lock` (uv2nix) and the npm lock (`importNpmLock`) through filtered source paths at evaluation time. Under `nix flake check --no-build` on a store that has not built those paths, evaluation fails with `path '…-hermes-python-source' is not valid`. A local store that has built them hides the failure, so it only shows on a cold store, including the CI `evaluate` job.

The pinned head is 11 days of upstream newer than the previous pin `e0550c97` (2026-10-09). The PR's base is 2026-10-20, so the pin also carries that upstream state, not only the two-file fix.

**Alternatives:** wait for #141834 to merge (ci stays red meanwhile); remove the hermes aspect; pin to the PR base `0b10b9f8`, which lacks the fix.
**Reason:** the operator chose to unblock ci now, accepting an unmerged upstream head and the larger upstream change.
**Revisit when:** #141834 is on the upstream default branch. Then point the declaration back at the default branch and relock.
