# Proposal

## Why

Both workstation configurations select the fleet baseline and GC, but neither exported host metrics. The published observability contract provides a remote-write lane that is settled enough to adopt without copying transport machinery. Journals are split into `adopt-fleet-journals`: replay policy, privacy and backend-retention questions are unresolved and under upstream review.

Two things changed after the metrics lane was implemented. The fleet replaced the single `telemetry` aspect with selectable bundles (`telemetry-metrics`, `telemetry-logs`, `telemetry-otlp`) plus realisations, removing `providers.*` and `realized`, so enablement is now expressed by aspect composition and the health registrations are contributed rather than declared by consumers. And a Pi trace producer now exists (`pi-otel`), so the trace lane is real rather than hypothetical — which moves its destination question into scope for the record, even though the decision itself is deferred.

## What Changes

- Select the fleet `telemetry-metrics` bundle and the `node-exporter` aspect on Legion and Spectre; `telemetry-otlp` is selected only because the Pi trace producer needs a local admission point.
- Send host metrics through one explicitly selected `fleet-metrics` remote-write destination, resolved from the canonical fleet service inventory at the flake-parts boundary. Keep shared policy in a reusable contributor, not in host files.
- Scrape locally only, and rely on the vmagent provider's own loopback health registration rather than declaring one: a running forwarder that is failing to deliver must stay observable.
- Record the trace lane as it stands: Pi admits traces locally and the fleet destination is contract-resolved, currently the published general record (`otel-collector/otlp`, `http://home-forge:4318`), which runtime evidence shows is store-only. The AI lane exists but its inventory record is unpublished, so the destination is not rebindable yet and no URL is hardcoded.
- Use stable host labels and vmagent's bounded disk queue. Document behaviour when a portable host loses tailnet access or suspends.
- Record the evaluated queue path in `docs/impermanence.md`, marking it active only after deployment.
- Provide separate configuration, deployment and delivery evidence per host. Endpoint reachability alone is not acceptance.

### Non-goals

No journal shipping and no Vector: the journal lane is `adopt-fleet-journals`. No decision on which AI backends see Pi sessions, and no trace-lane rebind before the fleet publishes the AI ingress coordinate: the choice between store-only, full AI fanout and a separate shaped route is deferred to its own decision once that record lands. No dashboards, new alert rules, backend changes, public listeners, Home Manager exporter, home reset, Arch wipe, build/cache adoption or broad input update. Beszel and notify responsibilities remain unchanged.

## Capabilities

### New Capabilities

- `workstation-observability`: host metrics export with canonical destinations, stable identity, local-only exposure, bounded offline buffering, forwarder health visibility and delivery verification.

### Modified Capabilities

None.

## Impact

Extends `modules/telemetry.nix`, adds `modules/node-exporter.nix`, selects the metrics bundle in both host compositions, adds a verification runbook and updates `ARCHITECTURE.md`, `docs/impermanence.md` and the transition task map. The fleet pin moved to `fb5ac7e3ac51` (the lanes-and-routes revision); no new credential or dependency.

Spectre can be configured and evaluated here, but deployment and delivery wait until it is online and its secret enrollment is complete. That does not block independent Legion acceptance.

`upstream-review.md` in this change is a review request to the fleet owner covering both lanes. It is not a dependency of this change. Its orphan-guard item is answered by disposition rather than code: dormant notify registrations staying inert is the approved guarantee, and the consumer-side hook assertion is the evidence.
