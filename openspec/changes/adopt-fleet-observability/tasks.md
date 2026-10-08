# Tasks

Implementation begins after approval. Switches and live outage exercises need separate operator approval.

> Pin note: tasks 1.1-1.3 and 2.1 were implemented against nix-fleet `23411143` (commit `a4114685`). Nix-fleet is replacing that API — `telemetry` becomes vocabulary only and selectable `telemetry-metrics`/`-logs`/`-otlp` bundles plus realisation aspects carry enablement, with `providers.*` and the orphan guards removed. Migrate the contributor, aspect selection and policy check to the published revision before any export leaves a host, and re-run 1.1-1.3 and 2.1 against it. Keep unrelated working-copy changes (package-update work) out of this change. `upstream-review.md` requests assessment only and does not gate these tasks.

## 1. Metrics contributor and forwarding health

- [x] 1.1 Extend `modules/telemetry.nix` with canonical metrics endpoint resolution and the metrics-only `fleet-metrics` destination, pinned by `pipelines.metrics`. Add `modules/node-exporter.nix` as a thin fleet import and select both aspects on both hosts. Verify canonical URL, local scraping, no implicit fan-out, and that Vector is not enabled.
- [x] 1.2 Register vmagent's loopback health scrape with an explicit host instance label. Validate port availability and the pinned version's actual backlog, error and drop series; record any missing signal as an upstream gap.
- [x] 1.3 Add evaluation-time policy checks for both hosts as designed, including the registrations-without-notify negative case. Verify a deliberately invalid policy fails the canonical no-build path.
- [ ] 1.4 Document the metrics and health lanes, Beszel coexistence and the shared-transport blind spot in `ARCHITECTURE.md` and the runbook. Reference backend-owner alert coverage or record it as an owned gap.
- [x] 1.5 Update `docs/impermanence.md` with the realised vmagent path, permissions/DynamicUser backing, budget and loss modes. No new home path or mount; Vector and OTel paths remain planned.

## 2. Integration gate and Legion rollout

- [x] 2.1 Format owned files, run the policy checks and the canonical flake check against the exact proposed tree, and build Legion's toplevel.
- [ ] 2.2 After explicit approval, deploy Legion; record provider units, loopback listeners, queue directory and effective hooks. Mark the persistence path active only after verification.
- [ ] 2.3 Verify fresh host-labelled node and vmagent-health samples; have the backend owner check for duplicate remote scrapes.
- [ ] 2.4 With approval, run a short destination outage and agent restart below capacity; observe local signals, eventual receipt and queue drainage.
- [ ] 2.5 Obtain owner evidence for allowed/denied route access, a controlled registered-unit failure and applicable delivery-health alert coverage; mark absent items pending with owners.

## 3. Spectre rollout and acceptance

- [ ] 3.1 When reachable and enrolled, build and deploy Spectre with approval; verify its own instance, storage and hooks. Otherwise retain configured-only status.
- [ ] 3.2 Repeat metrics, outage/restart and applicable checks on Spectre; Legion results do not count.
- [ ] 3.3 Reconcile the ledger and `settle-after-nixos-transition` task 2.1 (metrics part). Do not check off unperformed delivery. Journals and traces stay separate.

## Workflow follow-up

- Review the diff and persistence inventory before committing or pushing.
- Archive after applicable acceptance is complete or deferrals are explicit and owned.
