# Tasks

Implementation begins after approval. Switches and live outage exercises need separate operator approval.

> Status note: tasks 1.1-1.5 and 2.1 were implemented against nix-fleet `23411143` (commit `a4114685`). The API migration that followed — `telemetry` becomes contract-only, selectable `telemetry-metrics`/`-logs`/`-otlp` bundles plus `telemetry-vmagent`/`-vector`/`-otel-collector-*` realisations carry enablement, `providers.*` and `realized` are removed — has since landed at nix-fleet `fb5ac7e3ac51` in another session's commit (`546d763f`), which also composed `telemetry-otlp` for the Pi trace producer, removed our `scrape.vmagent-health` declaration, and added the trace destination. The migration is therefore done rather than pending: `telemetry-metrics` replaces `telemetry`, `node-exporter` stays, the health registration is provider-contributed (`healthPort = 8429`, `healthJob = "vmagent-health"`, `labels.instance = "<hostName>:vmagent"`), and the policy check reads that registry option plus the rendered listener instead of unit internals. `destinations.*`, `pipelines.*` and `scrape.*` kept their shapes. Dormant notify registrations staying inert is the approved guarantee, not a defect to guard against — the consumer-side hook assertion is the evidence. Keep unrelated working-copy changes out of this change. `upstream-review.md` requests assessment only and does not gate these tasks.

## 1. Metrics contributor and forwarding health

- [x] 1.1 Extend `modules/telemetry.nix` with canonical metrics endpoint resolution and the metrics-only `fleet-metrics` destination, pinned by `pipelines.metrics`. Add `modules/node-exporter.nix` as a thin fleet import and select both aspects on both hosts. Verify canonical URL, local scraping, no implicit fan-out, and that Vector is not enabled.
- [x] 1.2 ~~Register vmagent's loopback health scrape with an explicit host instance label.~~ Superseded by the provider-owned registration: the vmagent realisation contributes `services.telemetry.scrape.vmagent-health` on `127.0.0.1:8429` with job `vmagent-health` and `labels.instance = "<hostName>:vmagent"`. Our declaration was removed and the policy check asserts the registry entry, its loopback target and its host-distinct label. The pinned version's backlog, error and drop series remain the signals to inventory; a missing one stays an upstream gap.
- [x] 1.3 Add evaluation-time policy checks for both hosts as designed, including the registrations-without-notify negative case. Verify a deliberately invalid policy fails the canonical no-build path.
- [x] 1.4 Document the metrics and health lanes, Beszel coexistence and the shared-transport blind spot in `ARCHITECTURE.md` and the runbook. Reference backend-owner alert coverage or record it as an owned gap.
- [x] 1.5 Update `docs/impermanence.md` with the realised vmagent path, permissions/DynamicUser backing, budget and loss modes. No new home path or mount; Vector and OTel paths remain planned.
- [x] 1.6 Re-verify the lane against nix-fleet `fb5ac7e3ac51` after the migration: bundle selection, the provider-contributed health registration, the resolved destination and pipeline, and the policy check reading the registry rather than unit internals. Confirm the canonical check still fails on a deliberately invalid policy. (Recorded here because the migration landed outside this change's commits.)

## 2. Integration gate and Legion rollout

- [x] 2.1 Format owned files, run the policy checks and the canonical flake check against the exact proposed tree, and build Legion's toplevel.
- [ ] 2.2 After explicit approval, deploy Legion; record provider units, loopback listeners, queue directory and effective hooks. Mark the persistence path active only after verification.
- [ ] 2.3 Verify fresh host-labelled node and vmagent-health samples; have the backend owner check for duplicate remote scrapes.
- [ ] 2.4 With approval, run a short destination outage and agent restart below capacity; observe local signals, eventual receipt and queue drainage.
- [ ] 2.5 Obtain owner evidence for allowed/denied route access, a controlled registered-unit failure and applicable delivery-health alert coverage; mark absent items pending with owners.

## 3. Spectre rollout and acceptance

- [ ] 3.1 When reachable and enrolled, build and deploy Spectre with approval; verify its own instance, storage and hooks. Otherwise retain configured-only status.
- [ ] 3.2 Repeat metrics, outage/restart and applicable checks on Spectre; Legion results do not count.
- [ ] 3.3 Reconcile the ledger and `settle-after-nixos-transition` task 2.1 (metrics part). Do not check off unperformed delivery. Journals stay in `adopt-fleet-journals`; traces stay recorded-but-undecided.

## 4. Trace lane (decided and implemented)

The producer exists, the lane is wired, and the audience is decided: full sessions to the fleet AI ingress. Only the post-switch evidence remains.

- [x] 4.1 Rebound the trace destination to `otel-collector/ai-otlp` after relocking nix-fleet to the revision carrying it (published at `6f74d9a2`, pinned at `e2a4ac5d`), changing the endpoint name and nothing else — no hardcoded URL, no guessed port.
- [x] 4.2 Decided: AI fanout. Full sessions — prompts, completions and tool and agent spans — reach VictoriaTraces, Langfuse and Latitude. The general ingress stays store-only and is not used for this lane. Rationale and rejected alternatives are in `design.md` decision 6, including the fleet's sibling-pipeline mechanism for payload shaping if that is ever wanted — which is the first thing to reach for, not a second route.
- [x] 4.3 Resolved by the rebind: `ARCHITECTURE.md`'s claim that Pi's traces reach the gateway's Langfuse/Latitude fanout is now true, so it needs no correction. The general-ingress substitution it would have required is recorded in the runbook instead.
- [ ] 4.4 Evidence after the switch: run a Pi session on Legion and confirm one trace id in all three stores. The fleet owner's ingress verification is evidence about the ingress, not about this host.

## Workflow follow-up

- Review the diff and persistence inventory before committing or pushing.
- Archive after applicable acceptance is complete or deferrals are explicit and owned.
