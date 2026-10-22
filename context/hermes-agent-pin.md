# Hermes agent pin

## hermes-agent is pinned to an unmerged upstream PR head

**Id:** 6046b69e-3dcb-4842-a68c-eb9d046e04ed
**Type:** decision
**Status:** superseded
**Superseded by:** the fleet evaluator now primes source paths before validating (see `ci-fleet-build.md`, af1d8c00-3f3a-4217-945d-d20ea9b0abb7 and the pin entry there), and `modules/agents/hermes.nix` returns the input to the default branch. #141834 was still open when the pin was retired.
**Evidence:** confirmed
**Source:** NousResearch/hermes-agent#141750 (issue) and #141834 (PR, head `68ce9ec9`); `modules/agents/hermes.nix`

The `hermes-agent` input is declared at `68ce9ec9`, the head of PR #141834, not at the default branch. Upstream reads `uv.lock` (uv2nix) and the npm lock (`importNpmLock`) through filtered source paths at evaluation time. Under `nix flake check --no-build` on a store that has not built those paths, evaluation fails with `path '…-hermes-python-source' is not valid`. A local store that has built them hides the failure, so it only shows on a cold store, including the CI `evaluate` job.

The pinned head is 11 days of upstream newer than the previous pin `e0550c97` (2026-10-09). The PR's base is 2026-10-20, so the pin also carries that upstream state, not only the two-file fix.

**Alternatives:** wait for #141834 to merge (ci stays red meanwhile); remove the hermes aspect; pin to the PR base `0b10b9f8`, which lacks the fix.
**Reason:** the operator chose to unblock ci now, accepting an unmerged upstream head and the larger upstream change.
**Revisit when:** #141834 is on the upstream default branch. Then point the declaration back at the default branch and relock.

This entry is superseded: the declaration was returned to the default branch because the fleet's evaluation gate now primes source paths with a writable, IFD-disabled evaluation before the read-only check, which removes the cold-store failure the pin worked around. The upstream PR is unmerged, so a _selected_ hermes still fails a cold read-only evaluation run by hand; the pipelined gate does not.
