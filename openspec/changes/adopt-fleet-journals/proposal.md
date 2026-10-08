# Proposal

## Why

Journals from the workstations are not shipped. The fleet's JSON-line lane exists, but adopting it now would bake in unsettled choices: reader replay policy, the privacy and retention of exported logs, and Vector health registration. Nix-fleet is reviewing these (see `../adopt-fleet-observability/upstream-review.md`). This change records the intended journal adoption and gates it on those outcomes and on the metrics lane being accepted first.

## What Changes

- Compose the fleet `telemetry-logs` bundle with the `telemetry-vector` realisation, with an explicit, non-empty, exact system-unit allowlist; resolve `victorialogs/jsonline` from the canonical inventory.
- Set the reader to current-boot-only with no first-enable backfill (checkpoint resume preserved), preferring a typed fleet binding if one lands.
- Rely on Vector's provider-owned health registration if the realisation supplies one, and assert the registry entry; declare it locally only if it does not.
- Gate the first journal-enabled switch on reviewed backend access, retention, deletion and backup policy and on notify's journal-excerpt content.
- Verify positive and negative delivery markers, history/reboot semantics and short outages, per host.

### Non-goals

No traces, no user-session or desktop logs, no whole-journal or `init.scope` shortcuts, no redaction promise, no historical or cross-boot replay, no backend/ACL changes, no new alert rules.

## Capabilities

### New Capabilities

- `workstation-journals`: selected system-service journal export with privacy gates, explicit history policy, bounded buffering and delivery verification.

### Modified Capabilities

None.

## Impact

Extends `modules/telemetry.nix` and host policy, adds journal sections to the verification runbook and `docs/impermanence.md`. Depends on `adopt-fleet-observability` being implemented — the metrics lane is in place at nix-fleet `fb5ac7e3ac51` — and on upstream dispositions for replay policy and Vector health. Do not start implementation before both.
