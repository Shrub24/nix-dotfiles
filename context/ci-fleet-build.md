# CI fleet build

## Fleet build targets the non-VM aggregate

**Id:** 7bbc3cdd-841d-41a5-be91-ee15835dec49
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** nix-fleet `docs/runbooks/consumer-adoption.md` (Path A) and `.github/workflows/build-push-cache.yml` at tag v2 (commit 11a028b2)

`fleet-build.yml` calls nix-fleet's `build-push-cache.yml` with `targets: .#ciRoot`, `systems: x86_64-linux`, `runner_system: x86_64-linux` and `profile: ci`. The workflow passes `targets` to `nix-fast-build --flake` as one selection, so the target is an aggregate rather than `.#checks`. `ciRoot` links the legion and spectre toplevels, `treefmt` and `check-flake-file`, and leaves out every VM test. The VM tests are manual tools.

The calling workflow pins the nix-fleet commit behind the v2 tag, not the tag. The workflow's own header writes its reference as `@<sha>`.

**Alternatives:** `targets: .#checks` builds the three VM tests as well, which is more than CI needs. Pinning `@v2` follows the runbook example, but the runbook says a tag-shaped `job_workflow_ref` is unproven against the tailnet credential, which is documented at `@refs/heads/main`.
**Reason:** the VM tests are manual and should not run in CI. The tag form may fail the tailnet claims on the first run, and a commit pin avoids that without a credential change. Whether a commit pin passes the claims check is unverified until the first run.
**Revisit when:** the tailnet credential admits a tag-shaped reference, or a consumer needs the VM tests in CI.

Renovate owns the `nix-fleet` flake input and this workflow pin, as separate pull requests. A flake input that lags the pin means the coordinator's cache facts and the flake's nixpkgs can disagree, which causes cache misses rather than failures.

## Validate keeps no second builder

**Id:** 0c3e2a51-6f7d-4b8e-9a3c-2d5e8f1b7a40
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** `.github/workflows/validate.yml` before this change; nix-fleet runbook section 1 and `docs/contracts/update-candidates.md`

`ci.yml` is the only validation caller, and it calls nix-fleet's `validate.yml`, the one definition of valid. The former local `validate.yml` is gone, and its `checks-build` job with it: that job named `statix` and `deadnix` as flake checks, but both are devShell tools in `modules/flake/tooling.nix`, so the job could not resolve them.

**Alternatives:** keep a local validation file and add statix and deadnix as flake checks, which would keep a second definition of valid.
**Reason:** the contract makes the fleet's `validate.yml` the definition that both the contributor path and the pipeline call, so a human pull request and a candidate are judged the same way.
**Revisit when:** Statix and Deadnix need to run in CI rather than only at pre-commit through lefthook. Adding them to the flake-check job is the cheap option.

## Path B candidate pipeline runs under the label policy

**Id:** 1ad0c35a-f1ba-44a2-bd81-f27079083b91
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** nix-fleet `docs/contracts/update-candidates.md` (consumer adoption and policy sections)

The repository consumes nix-fleet's pipeline through thin trigger files: `ci.yml`, `pipeline.yml`, `promote.yml`, `accept.yml` and `candidate-sweep.yml`, all pinned to the commit behind the v2 tag. `PROMOTION_POLICY` is `label`. Candidate builds use `CANDIDATE_TARGETS=.#ciRoot` with x86_64-linux, so VM tests are not built in the pipeline either.

The repository holds `.github/scripts/prepare-candidate.sh` and `promote-candidate.sh`, copied verbatim from the pinned commit. The validation job runs the preparation script from the default branch, and promotion runs the promote script from `main`, so the fleet's own copies would not be used.

**Alternatives:** call the scripts from the pinned nix-fleet revision, which would remove the copies. nix-fleet's workflows do not do this today, and changing them is a nix-fleet change, which this repository does not make.
**Reason:** the trusted procedure must come from the default branch, and the runbook lists no script in consumer adoption. The copies are the only way promotion runs here.
**Revisit when:** nix-fleet resolves these scripts from the pinned revision, or the copies drift from the pinned commit. Compare with `git show 11a028b2:.github/scripts/promote-candidate.sh`.

Before this pipeline can promote, the App, its `automation` environment secret, `AUTOMATION_APP_ID`/`AUTOMATION_APP_SLUG`, and the `update-candidate` ruleset need to exist. The ruleset is deliberately absent until one candidate has validated and promoted by hand.
