# Workstation observability

## Purpose

Define host-local metrics and selected system-service journal export for the managed workstations, including privacy, offline behaviour and evidence required to establish delivery.

## ADDED Requirements

### Requirement: Both workstation configurations select the approved lanes

Legion and Spectre SHALL select host metrics and system-service journal export through the fleet aspects. Trace ingestion, trace destinations and remote telemetry ingress SHALL remain disabled in this change. Existing Beszel monitoring and notify dispatch SHALL remain selected.

#### Scenario: A workstation configuration is evaluated

- **WHEN** either workstation configuration is evaluated
- **THEN** the metrics exporter, metrics forwarder and journal shipper are configured
- **AND** no OTLP listener or trace relay is configured

### Requirement: Destinations come from the fleet service inventory

Metrics SHALL resolve `victoriametrics/remote-write` and journals SHALL resolve `victorialogs/jsonline` through the fleet's tailnet route. Consumers SHALL NOT duplicate their host, port or URL or route these lanes through the trace gateway.

#### Scenario: The fleet publishes new backend coordinates

- **WHEN** a fleet pin carrying changed backend coordinates is evaluated
- **THEN** both export destinations follow the canonical inventory without a local address edit

### Requirement: Metrics are scraped locally with distinct host identity

The node exporter SHALL bind only to loopback and be scraped on its own host. Remote-write samples SHALL retain a stable instance identifying that host rather than its loopback address. Journal stream identity SHALL retain the origin hostname and system unit.

#### Scenario: Both machines export node metrics

- **WHEN** the backend receives metrics from Legion and Spectre
- **THEN** their instance labels are distinct and correspond to their hostnames and exporter ports
- **AND** neither exporter is exposed on a LAN or tailnet interface

#### Scenario: Journals arrive at the backend

- **WHEN** an allowed system unit emits a journal entry
- **THEN** the exported entry retains its origin hostname and system-unit identity

### Requirement: Journal export is explicitly allowlisted

Each host SHALL use an explicit, non-empty allowlist of operational system-unit names matched against trusted journal unit metadata. Host-specific additions SHALL name actual enabled system services. An empty allowlist SHALL NOT qualify as an accepted configuration.

#### Scenario: An allowed system service emits a marker

- **WHEN** a unique marker is emitted from a genuinely allowlisted system unit
- **THEN** the marker is observable in the journal backend with that unit identity

#### Scenario: A logger tag imitates an allowed unit

- **WHEN** an excluded unit emits an entry whose message or logger tag names an allowed unit
- **THEN** that entry is not exported on the strength of its text or tag

### Requirement: User-session logs and secrets have no blanket export path

The initial allowlist SHALL exclude user-manager units, desktop/session units and blanket kernel or whole-journal selection. Allowlisting SHALL NOT be described as redaction. The selected units' potential sensitive output and disk-buffer copies SHALL be documented before deployment.

#### Scenario: A user service emits a marker

- **WHEN** an interactive session or Home Manager user service emits a unique marker
- **THEN** it is not exported by the system-service journal policy

#### Scenario: An excluded system unit emits a marker

- **WHEN** a system unit outside the allowlist emits a unique marker during the verification window
- **THEN** that marker is absent from the backend after positive allowed-unit delivery has been established

### Requirement: Offline buffering is bounded and persistent

The metrics forwarder SHALL use the fleet's 1 GiB disk budget per destination and oldest-data eviction. The journal shipper SHALL use a 512 MiB disk buffer with blocking overflow. Queue state SHALL survive agent restart on the persistent root. No guarantee of lossless export beyond queue capacity or journal retention SHALL be made.

#### Scenario: A destination is unavailable below the buffer limit

- **WHEN** a destination is unavailable, data is buffered below capacity, and its forwarding agent restarts
- **THEN** buffered data remains available for export when connectivity returns
- **AND** verification demonstrates eventual backend receipt rather than merely a running agent

#### Scenario: An offline workstation exhausts its budget

- **WHEN** the metrics queue reaches its limit or the journal buffer fills
- **THEN** metrics evict oldest buffered data and journal reading blocks
- **AND** documentation states that journal rotation and boot boundaries can still cause loss

### Requirement: Exporter failures use existing notify dispatch

The node exporter, metrics forwarder and journal shipper SHALL have effective failure hooks through the selected fleet notify capability and its existing system topic. Declaring event registrations without an active dispatcher SHALL NOT satisfy this requirement.

#### Scenario: A registered exporter unit fails under a controlled test

- **WHEN** the verification procedure exercises a registered-unit failure
- **THEN** a notification reaches the existing system topic
- **AND** the unit is restored without retaining a test failure or configuration override

### Requirement: Acceptance distinguishes configuration from delivery per host

Evidence SHALL distinguish configured, deployed and delivering for each host. Delivery requires fresh host metrics, positive and negative journal markers, offline/restart recovery and applicable fleet network/notification checks. HTTP reachability and offline derivation checks SHALL NOT be reported as end-to-end delivery.

#### Scenario: Spectre is unavailable for deployment

- **WHEN** Spectre evaluates successfully but cannot undergo live deployment and verification
- **THEN** its state is recorded as configured only
- **AND** Legion can be independently deployed and accepted without claiming Spectre delivery

#### Scenario: Backend reachability succeeds

- **WHEN** a GET request reaches a backend listener
- **THEN** that result alone does not satisfy delivery acceptance
