# CI fleet build

## Fleet build targets the non-VM aggregate

**Id:** 7bbc3cdd-841d-41a5-be91-ee15835dec49
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** nix-fleet `docs/runbooks/consumer-adoption.md` (Path A) and `.github/workflows/build-push-cache.yml` at the revision this repository's flake locks

`fleet-build.yml` calls nix-fleet's `build-push-cache.yml` with `targets: .#ciRoot`, `systems: x86_64-linux`, `runner_system: x86_64-linux` and `profile: ci`, and grants `contents: read` plus `id-token: write`, which the called workflow declares. The workflow passes `targets` to `nix-fast-build --flake` as one selection, so the target is an aggregate rather than `.#checks`. `ciRoot` links the legion and spectre toplevels, `treefmt`, `check-flake-file` and the retention root, and leaves out every VM test. The VM tests are manual tools.

Every workflow pin is a full SHA, and it is the revision `flake.lock` holds: a workflow that lags the lock would render coordinator facts the flake does not agree with.

**Alternatives:** `targets: .#checks` builds the three VM tests as well, which is more than CI needs. A tag (`@v1`, `@v2`) is a legacy milestone; the tags predate bundled actions and nested retention, so a tag pin silently loses behaviour the caller then has to supply itself.
**Reason:** the VM tests are manual and should not run in CI, and the fleet's coordinator needs the cache facts its own revision carries.
**Revisit when:** a consumer needs the VM tests in CI, or Renovate moves the flake input and the workflow pins at different times.

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

The repository consumes nix-fleet's pipeline through thin trigger files: `ci.yml`, `pipeline.yml`, `promote.yml`, `accept.yml` and `candidate-sweep.yml`, all pinned to the revision `flake.lock` holds. `PROMOTION_POLICY` is `label`. Candidate builds use `CANDIDATE_TARGETS=.#ciRoot` with x86_64-linux, so VM tests are not built in the pipeline either.

Each caller grants the union the called jobs declare: `pipeline.yml` needs contents, statuses, pull requests and OIDC write, and `promote.yml` needs contents plus OIDC write, because its dependent pin job joins the tailnet. A narrower grant fails the call at startup with no logs.

Neither repository file supplies a script: validation and promotion use the actions bundled with the pinned workflow revision. An earlier revision read `prepare-candidate.sh` and `promote-candidate.sh` from this repository's default branch, and copies were carried here for that reason until the bundled actions replaced them.

**Alternatives:** copy the scripts and keep them current by hand, which is what the earlier revision required.
**Reason:** a bundled action is the revision the caller pinned, so a consumer tracks one SHA instead of a SHA plus two drifting copies.
**Revisit when:** a caller needs behaviour the bundled actions do not expose.

Before this pipeline can promote, the App, its `automation` environment secret, `AUTOMATION_APP_ID`/`AUTOMATION_APP_SLUG`, and the `update-candidate` ruleset need to exist. The ruleset is deliberately absent until one candidate has validated and promoted by hand.

## Retention pins the fleet's cache-root aggregate

**Id:** af1d8c00-3f3a-4217-945d-d20ea9b0abb7
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** nix-fleet `modules/flake/cache-root.nix`, `docs/contracts/ci.md` (retention) and `docs/contracts/update-candidates.md` (promotion inputs)

`modules/flake/ci.nix` imports `inputs.nix-fleet.flakeModules.cacheRoot`, which publishes `packages.<system>.cache-root` as a linkFarm over every other published package, and `ciRoot` includes that root. Promotion passes `targets: .#packages`, `subject: cache-root` and `systems: x86_64-linux` explicitly rather than relying on `CACHE_PIN_*`.

**Alternatives:** a hand-written aggregate over this repository's own packages, which would drop the fleet packages the overlay publishes and make the retention root disagree with the build. Omitting the root from `ciRoot` leaves it unbuilt, and `pins create` then refuses the path by name.
**Reason:** retention protects an artefact closure from the cache's own garbage collection, and pinning asserts presence rather than measuring it. The set the fleet build builds must therefore contain the set promotion pins.
**Revisit when:** retention should cover the host toplevels rather than packages, which the contract deliberately avoids because a check changes whenever its inputs do.
