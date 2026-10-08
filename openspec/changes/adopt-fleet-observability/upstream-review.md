# Review request: fleet observability adoption

## Objective and scope

Review the gaps exposed while proposing metrics and selected system journals for Legion and Spectre. Both are portable NixOS workstations; neither should be assumed continuously online. Return findings, ownership and a minimal recommended change set. This brief authorises review only: no implementation, deployment, consumer lock update or backend changes.

**Baseline:** nix-fleet `23411143acdacf676e49ce7d68bd5fd6d57ec47d`, Vector 0.58.0, local runtime probes on systemd 261.3. Recheck current HEAD, existing issues/tests and `context/` decisions before acting. A finding already fixed upstream needs a reference, not another fix.

**Consumer plan, split in two:**

- `adopt-fleet-observability` adopts the metrics lane now: canonical tailnet remote-write route, one pinned `fleet-metrics` destination, loopback node-exporter, vmagent health scrape, bounded vmagent queue.
- `adopt-fleet-journals` is gated on your dispositions of items 2–4 below plus accepted metrics adoption. It plans explicit exact system-unit allowlists, current-boot-only with no first-enable backfill, Vector loopback health metrics, and a backend data-policy gate.

Traces are out of scope for both. Items 1 and 3 touch the metrics change; the rest affect only journals.

## Priority review items

### 1. Notification registrations can evaluate without a dispatcher

**Classification:** confirmed mechanism/documentation contradiction; locally mitigated, not an adoption blocker.

`modules/notifications/notify/_notify-events.nix:8–10` says registrations without notify fail as unknown options. The fragment declares `services.notify.events` at `:69–108`, and telemetry providers import it. The notify aspect alone attaches hooks (`modules/notifications/notify.nix:335–369`).

An evaluation-only consumer probe selected telemetry + node-exporter with a valid metrics destination but omitted notify. Observed fields:

```json
{
  "notifyPresent": false,
  "notifyPolicyDeclared": true,
  "registered": ["prometheus-node-exporter", "vmagent"],
  "vmagentEnabled": true,
  "vmagentOnFailure": []
}
```

This shows inert event registrations. It was not a toplevel build or delivery test. Both consumer hosts already select notify and will check effective hooks.

**Request:** enforce the documented orphan-registration boundary, or revise the promise and explain why silent registrations are acceptable. Prefer a guard analogous to telemetry's own orphan guard.

**Acceptance:** a registration-bearing composition without notify fails for that reason; selecting notify yields additive hooks and a dispatcher without replacing existing unit hooks. Cover package-provided units separately from declared services.

**Probe shape:** evaluate a `nixosSystem` with sops options, the fleet `telemetry` and `node-exporter` aspects, a metrics-only `prometheus-remote-write` destination, hostname/platform/stateVersion, and no notify aspect. Inspect registered events, `services.vmagent.enable`, notify service presence and rendered failure hooks.

### 2. Make journal history and reboot policy explicit

**Classification:** documented provider default with a fleet-policy/documentation gap; not a claim that persistent buffering is broken.

Vector defaults `current_boot_only=true` (`src/sources/journald.rs:111–112,316`). The fleet renderer leaves it implicit. Start logic uses a saved cursor first, then `since_now`, otherwise a historical start (`:759–766`). Checkpoint state lives under the source component directory (`:349–371`); fleet's `journald` source yields `/var/lib/vector/journald/checkpoint.txt`.

Metadata-only local probes using the reader's first-start and prior-boot-cursor command shapes found current-boot records and no older-boot records despite accessible older journals. An offline host can reboot with unread old-boot records retained by journald but excluded by the reader. Already-buffered data and unread journal data are different recovery obligations.

**Request:** document and, if appropriate, expose typed boot/history policy and initial start position. Decide whether the baseline intentionally excludes old boots or should allow retained-journal replay for portable hosts. Do not assume maximum replay is privacy-safe.

**Acceptance:** cover first enable with and without a checkpoint, same-boot restart, host reboot and a rotated/unavailable cursor using a disposable journal/VM fixture. Distinguish buffered replay, unread-history loss and duplicates. Current-boot scope is locally corroborated; invalid-cursor recovery is untested.

### 3. Expose forwarding health and test the approved delivery lanes

**Classification:** adoption coverage gap and possible reusable mechanism improvement.

The observability contract requires delivery/backlog visibility (`docs/contracts/observability.md:187–192`). Process-active and OnFailure hooks cannot detect rejection, retry or a growing queue. vmagent exposes a loopback metrics surface on 8429 (`modules/telemetry/vmagent.nix:145–165`); the metrics change registers it. The journals change would add Vector's native `internal_metrics` with a loopback exporter.

**Request:** assess a provider-owned health registration or default consumers can select without rebuilding implementation details. Document the pinned backlog, send/enqueue-error, dropped-data and absent-delivery metrics and which alert-rule owner consumes them. Keep laptop availability policy consumer-owned; do not apply an always-online server rule indiscriminately.

Audited `checks.telemetry-delivery`/`telemetry-ingress` cover OTLP paths, not production vmagent/Vector recovery (`docs/contracts/telemetry.md:688–696`). Inventory other native tests before adding coverage.

**Acceptance:** deterministic remote-write and JSON-line outage/restart tests show recovery below capacity and observable backlog/errors. Health listeners stay loopback-only; no duplicate scrape or second watchdog. Distinguish same-transport self-health from independent central missing-data detection.

### 4. Journal enablement plus an empty list exports everything

**Classification:** intentional, documented default with a privacy footgun.

`lib/telemetry-contract.nix:420–427` defines an empty `includeUnits` as all units. The baseline forbids whole-journal adoption (`docs/contracts/observability.md:134–147`), but mechanism validation does not enforce it. Our consumer plan checks for non-empty lists.

**Request:** consider an explicit whole-journal opt-in or a baseline-layer non-empty assertion. Preserve genuine full-journal use only through deliberate policy; do not silently reinterpret an existing empty list.

**Acceptance:** enabled selected-unit shipping with an omitted or empty list cannot pass baseline validation; any full-journal exception is explicit and migration-compatible.

## Clarify these limitations in the contract

### Service output is narrower than service-associated journal history

Direct source evidence: Vector 0.58.0 `src/sources/journald.rs:114–156,256–262,1011–1027`.

- `include_units` is exact, case-sensitive `_SYSTEMD_UNIT` matching, not `journalctl -u`.
- PID 1 lifecycle records generally belong to `init.scope` and are not selected by the service's name (documented in Vector at `:120–121`).
- Template names and globs do not match instances; each instance needs its exact name.
- Records without an included unit are excluded. Exclude matches take precedence; overlapping include/exclude declarations are rejected (`:355–367`).

**Request:** state whether services' own output is the intended baseline. Do not prescribe wholesale `init.scope` inclusion to regain lifecycle records. If broader service diagnostics are wanted, design narrow selectors that preserve trusted-origin and referenced-unit boundaries; raw match maps alone may not express the intended conjunction safely.

### User-unit selection needs a different boundary

The fleet exposes system-unit filters, not individual `_SYSTEMD_USER_UNIT` selection. A collected transient user-service probe returned `_SYSTEMD_UNIT=user@1000.service` alongside a distinct `_SYSTEMD_USER_UNIT`. Selecting the former sweeps all user services.

**Request:** document this boundary. Individual user-unit export is an optional extension, not required for system-only adoption. Do not recommend a blanket user-manager shortcut.

### Privacy policy extends beyond the allowlist

The contract assigns store access, retention, deletion and backups to consumers (`docs/contracts/observability.md:141–147`). Notify separately defaults to invocation journal excerpts (`modules/notifications/notify/_notify-events.nix:51–55`). Dropping a unit from selection does not delete buffered or backend copies.

**Request:** identify the backend-policy owner and evidence a consumer should reference before shipping. Clarify snapshot/queue retention, existing notify output and revocation/deletion expectations without inventing a universal retention period.

## Wider architectural questions — optional, not defects

1. **Lane-specific acceptance:** distinguish push-only metrics/log clients from OTLP ingress/gateways, and local checks from backend/operator checks. Which categories are not applicable, externally pending or adoption-blocking? A GET and configured units remain insufficient evidence.
2. **Health ownership:** can the provider contribute stable health scrape jobs through the existing registration interface rather than each consumer binding native settings? Keep alert thresholds out of implementation defaults.
3. **Unit/log ownership:** can unit owners describe eligible log sources and sensitivity while consumers still explicitly admit them? Avoid turning registration into automatic collection or another ambient argument bus.
4. **Queue identity and catalogue moves:** document what survives destination URL changes, source/exporter renames and root-snapshot rollback. A stable Nix attribute name is not proof of queue migration. Who coordinates drain/migration when canonical coordinates move?
5. **Tailnet route assurance:** the resolver constructs a hostname URL (`lib/service-endpoints.nix:24–46`). Does runtime resolution stay tailnet-bound when MagicDNS/Tailscale is unavailable? No fallback misrouting was reproduced; this is a hardening question, not an established vulnerability.
6. **Portable-host budgets:** are fixed queue budgets plus documented eviction/blocking adequate, or should minimal consumer tuning be part of the public contract? Avoid knobs without a demonstrated need.

## Requested response

For each item, return one disposition: confirmed gap, already fixed, intentional/document, consumer-owned, needs design, or unsupported. Cite current code and decisions and any existing regression. Separate the smallest justified fixes from optional extensions and say which would affect compatibility or consumer pins.

Do not merge all questions into a new framework. Return a prioritized review and proposed patch scope first; implementation and deployment need separate approval.
