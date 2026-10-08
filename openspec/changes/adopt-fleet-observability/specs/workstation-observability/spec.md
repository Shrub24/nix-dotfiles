# Workstation observability

## Purpose

Define host-local metrics export for the managed workstations, including identity, offline behaviour, forwarder health and the evidence required to establish delivery. Journal export is specified separately.

## ADDED Requirements

### Requirement: Both workstation configurations select the metrics lane

Legion and Spectre SHALL select host metrics export through the fleet `telemetry` and `node-exporter` aspects. Trace ingestion, trace destinations, remote telemetry ingress and journal shipping SHALL remain disabled by this capability. Existing Beszel monitoring and notify dispatch SHALL remain selected.

#### Scenario: A workstation configuration is evaluated

- **WHEN** either workstation configuration is evaluated
- **THEN** the metrics exporter and metrics forwarder are configured
- **AND** no OTLP listener, trace relay or journal shipper is configured

### Requirement: The destination comes from the fleet service inventory

Metrics SHALL resolve `victoriametrics/remote-write` through the fleet's tailnet route and flow through one explicitly selected metrics destination. Consumers SHALL NOT duplicate its host, port or URL or route metrics through the trace gateway.

#### Scenario: The fleet publishes new backend coordinates

- **WHEN** a fleet pin carrying changed backend coordinates is evaluated
- **THEN** the destination follows the canonical inventory without a local address edit
- **AND** queue continuity for the changed destination is reviewed before rollout

#### Scenario: A second metrics destination is later declared

- **WHEN** another destination is added to the configuration
- **THEN** host metrics still flow only to the explicitly selected pipeline until it is changed deliberately

### Requirement: Metrics are scraped locally with distinct host identity

The node exporter SHALL bind only to loopback and be scraped on its own host. Remote-write samples SHALL carry a stable instance identifying that host rather than its loopback address.

#### Scenario: Both machines export node metrics

- **WHEN** the backend receives metrics from Legion and Spectre
- **THEN** their instance labels are distinct and correspond to their hostnames and exporter ports
- **AND** neither exporter is exposed on a LAN or tailnet interface

### Requirement: Offline buffering is bounded and persistent

The metrics forwarder SHALL use the fleet's 1 GiB disk budget per destination with oldest-data eviction. Queue state SHALL survive agent restart on the persistent root. No guarantee of lossless export beyond queue capacity SHALL be made, and queues SHALL NOT be purged or restored as routine cleanup.

#### Scenario: The destination is unavailable below the buffer limit

- **WHEN** the destination is unavailable, data is buffered below capacity and the forwarder restarts
- **THEN** buffered data is exported when connectivity returns

### Requirement: Forwarding health is continuously observable

Both hosts SHALL export host-distinct forwarder delivery-health metrics through the selected pipeline, with a loopback-only health listener. Backlog, send-error and dropped-data visibility and applicable availability-aware central alert coverage SHALL be verified or recorded as owned acceptance gaps. Invented metric names and process-active-only claims SHALL NOT substitute for evidence.

#### Scenario: The forwarder stays active while delivery fails

- **WHEN** a destination outage leaves the forwarding process running
- **THEN** local error and backlog signals remain observable
- **AND** health samples reach the backend after connectivity returns

#### Scenario: A laptop is intentionally asleep

- **WHEN** the host suspends
- **THEN** acceptance does not rely on an unreviewed always-online server alert rule

### Requirement: Exporter failures use existing notify dispatch

Failure events for the exporter and forwarder SHALL render through the already-selected notify dispatcher to the existing system topic, without duplicate local registration.

#### Scenario: Registrations exist without a dispatcher

- **WHEN** a composition registers failure events but does not select notify
- **THEN** the policy check fails rather than accepting inert hooks

### Requirement: Acceptance evidence is per host and end to end

Evidence SHALL distinguish configured, deployed and delivering per host. Acceptance requires fresh host and forwarder metrics, offline/restart recovery and applicable network, notification and alert checks. Policy regressions SHALL fail the canonical evaluation path. Missing external evidence SHALL remain an owned gap, not a pass. HTTP reachability or unbuilt checks SHALL NOT count as delivery.

#### Scenario: Spectre is offline during Legion acceptance

- **WHEN** Legion's applicable categories pass and Spectre is unreachable
- **THEN** Spectre is recorded as configured only
- **AND** adoption is not reported as fully accepted
