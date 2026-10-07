# Proposal

## Why

Both workstation configurations now select the fleet baseline and GC, but neither exports diagnostics to the fleet's metrics and journal backends. The published observability contract now provides those routes; adopt it without copying the transport machinery or shipping whole workstation journals.

## What Changes

- Select the fleet telemetry and node-exporter aspects on Legion and Spectre.
- Send host metrics through the fleet remote-write lane and system-service journals through an explicit, non-empty allowlist.
- Resolve both destinations from the canonical fleet service inventory at the flake-parts boundary. Keep shared policy in a reusable contributor rather than repeating it in host files.
- Use stable host labels, local-only scraping and the fleet's bounded disk-backed queues. Document behaviour when a portable host loses tailnet access or suspends.
- Record the evaluated queue paths in `docs/impermanence.md`, keeping root persistent and marking paths active only after deployment.
- Provide separate configuration, deployment and delivery evidence for each host. Endpoint reachability alone is not acceptance.

### Non-goals

No traces relay or Pi trace plugin yet: there is no selected producer. No dashboards, new alert rules, backend changes, public listeners, Home Manager journal exporter, home reset, Arch wipe, build/cache adoption or broad input update. Existing Beszel and notify responsibilities remain unchanged. Interactive application/session logs are excluded from the initial journal policy.

## Capabilities

### New Capabilities

- `workstation-observability`: host metrics and narrowly selected system-service journal export, with canonical destinations, stable identity, local privacy boundaries, bounded offline buffering and delivery verification.

### Modified Capabilities

None. The existing current-host and dendritic composition contracts remain constraints on this implementation.

## Impact

The implementation will extend `modules/telemetry.nix`, add a local node-exporter contributor, and select the resulting aspects in both host compositions. It will add a verification runbook and update `ARCHITECTURE.md`, `docs/impermanence.md` and the transition task map. Transport units and packages come from the locked nix-fleet aspects; this proposal introduces no new credential or upstream dependency.

Spectre can be configured and evaluated here, but deployment and delivery must wait until it is online and its existing secret-enrollment prerequisites are satisfied. That does not block independent Legion acceptance.
