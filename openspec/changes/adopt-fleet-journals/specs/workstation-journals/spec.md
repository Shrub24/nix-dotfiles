# Workstation journals

## Purpose

Define selected system-service journal export for the managed workstations, including privacy, history policy, offline behaviour and delivery evidence.

## ADDED Requirements

### Requirement: Journal destination comes from the fleet inventory

Journals SHALL resolve `victorialogs/jsonline` through the fleet's tailnet route and SHALL NOT be routed through the trace gateway or duplicate the URL locally.

#### Scenario: Backend coordinates change

- **WHEN** a fleet pin carries changed coordinates
- **THEN** the journal sink follows the inventory without a local edit

### Requirement: Journal export is explicitly allowlisted

Each host SHALL use an explicit, non-empty allowlist of exact operational system-unit names matched against `_SYSTEMD_UNIT`. Additions SHALL name realised system services. An empty list, logger tag or template pattern SHALL NOT qualify. Documentation SHALL distinguish services' own output from system-manager lifecycle records.

#### Scenario: An allowed service emits a marker

- **WHEN** a unique marker is emitted from an allowlisted system unit
- **THEN** it is observable in the backend with that unit identity and the origin hostname

#### Scenario: A logger tag imitates an allowed unit

- **WHEN** an excluded unit's message or tag names an allowed unit
- **THEN** the entry is not exported on the strength of that text

#### Scenario: The manager reports an allowed service transition

- **WHEN** PID 1 emits a lifecycle record attributed to `init.scope`
- **THEN** it is excluded and no `journalctl -u` equivalence is promised

### Requirement: No blanket export path for user or sensitive logs

The initial allowlist SHALL exclude user managers, `init.scope`, desktop and session units, greeter and Home Manager activation units, and kernel or whole-journal selection. Adding an excluded unit SHALL require a content review. Allowlisting SHALL NOT be described as redaction, and buffer, snapshot and notification-excerpt copies SHALL be documented before deployment.

#### Scenario: A user service emits a marker

- **WHEN** a user-session service emits a unique marker
- **THEN** it is not exported

#### Scenario: An excluded system unit emits a marker

- **WHEN** a system unit outside the list emits a marker after positive delivery is established
- **THEN** the marker is absent from the backend

### Requirement: Journal history policy is explicit

The reader SHALL collect the current boot only and start from new records when no checkpoint exists; a saved checkpoint SHALL take precedence. Unread previous-boot records and previously filtered entries SHALL NOT be backfilled, and this SHALL be documented. Historical replay requires a separately reviewed change.

#### Scenario: First enable without a checkpoint

- **WHEN** the reader starts without saved state
- **THEN** earlier selected-unit records are not backfilled

#### Scenario: Restart within a boot

- **WHEN** the agent restarts with a saved cursor
- **THEN** collection resumes from the cursor rather than skipping backlog

#### Scenario: Reboot with unread records

- **WHEN** previous-boot records are unread at reboot
- **THEN** they are not collected and disk buffers are not presented as guaranteeing their recovery

### Requirement: Backend data policy gates deployment

Before a journal-enabled switch, reviewed backend access, retention, deletion and backup policy and local queue and snapshot retention SHALL be referenced. Missing evidence SHALL block deployment. Removing a unit SHALL NOT be reported as deleting queued or stored copies.

#### Scenario: Retention or access policy is unknown

- **WHEN** configuration evaluates but the policy is unreviewed
- **THEN** deployment stays pending

### Requirement: Journal buffering is bounded

The shipper SHALL use a 512 MiB disk buffer with blocking overflow on persistent root. No lossless guarantee beyond buffer capacity or journal retention SHALL be made.

#### Scenario: Destination unavailable below capacity

- **WHEN** the destination is down, data is buffered and the shipper restarts
- **THEN** buffered data is exported on reconnection

### Requirement: Shipper health is observable

The shipper SHALL expose loopback-only host-distinct delivery-health metrics through the metrics pipeline, with backlog, error and drop visibility verified or recorded as owned gaps.

#### Scenario: Shipper active but failing

- **WHEN** the destination rejects data while the process runs
- **THEN** local error and backlog signals are observable

### Requirement: Acceptance evidence is per host and end to end

Evidence SHALL distinguish configured, deployed and delivering per host and include positive and negative markers, history semantics, outage recovery and applicable access and notification checks. Policy regressions SHALL fail the canonical evaluation path; missing external evidence SHALL remain an owned gap.

#### Scenario: One host lacks evidence

- **WHEN** only Legion has delivering evidence
- **THEN** Spectre is recorded as configured only
