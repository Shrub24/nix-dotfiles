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
**Source:** `.github/workflows/validate.yml` before this change; nix-fleet runbook section 1 (the fleet job is the only builder)

`validate.yml` runs `nix flake check --no-build --no-write-lock-file` and nothing that builds. The former `checks-build` job is removed: it named `statix` and `deadnix` as flake checks, but both are devShell tools in `modules/flake/tooling.nix`, so the job could not resolve them.

**Alternatives:** keep the job and add statix and deadnix as flake checks, which would keep a second builder in routine CI.
**Reason:** the runbook says a repository that builds in its own CI should stop once the fleet path is green, because two publishers for one closure is how a cache starts lying.
**Revisit when:** Statix and Deadnix need to run in CI rather than only at pre-commit through lefthook. Adding them to the flake-check job is the cheap option.
