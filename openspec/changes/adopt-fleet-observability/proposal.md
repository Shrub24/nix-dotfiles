# Proposal

## Why

Both workstation configurations select the fleet baseline and GC, but neither exports host metrics. The published observability contract provides a remote-write lane that is settled enough to adopt now, without copying transport machinery. Journals are split into `adopt-fleet-journals`: replay policy, privacy and backend-retention questions are unresolved and under upstream review.

## What Changes

- Select the fleet `telemetry` and `node-exporter` aspects on Legion and Spectre.
- Send host metrics through one explicitly selected `fleet-metrics` remote-write destination, resolved from the canonical fleet service inventory at the flake-parts boundary. Keep shared policy in a reusable contributor, not in host files.
- Scrape locally only. Register vmagent's own loopback health metrics so a running forwarder that is failing to deliver is observable.
- Use stable host labels and vmagent's bounded disk queue. Document behaviour when a portable host loses tailnet access or suspends.
- Record the evaluated queue path in `docs/impermanence.md`, marking it active only after deployment.
- Provide separate configuration, deployment and delivery evidence per host. Endpoint reachability alone is not acceptance.

### Non-goals

No journal shipping and no Vector: the journal lane is `adopt-fleet-journals`. No traces relay or Pi trace plugin (no producer). No dashboards, new alert rules, backend changes, public listeners, Home Manager exporter, home reset, Arch wipe, build/cache adoption or broad input update. Beszel and notify responsibilities remain unchanged.

## Capabilities

### New Capabilities

- `workstation-observability`: host metrics export with canonical destinations, stable identity, local-only exposure, bounded offline buffering, forwarder health visibility and delivery verification.

### Modified Capabilities

None.

## Impact

Extends `modules/telemetry.nix`, adds `modules/node-exporter.nix`, selects both aspects in both host compositions, adds a verification runbook and updates `ARCHITECTURE.md`, `docs/impermanence.md` and the transition task map. The fleet pin stays at `23411143`; no new credential or dependency.

Spectre can be configured and evaluated here, but deployment and delivery wait until it is online and its secret enrollment is complete. That does not block independent Legion acceptance.

`upstream-review.md` in this change is a review request to the fleet owner covering both lanes. It is not a dependency of this change.
