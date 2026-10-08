# telemetry metrics

## The metrics lane is adopted now, journals wait

**Id:** 6d655191-ec1f-4ab3-8ee4-e3aa216fc430
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Revisit when:** `adopt-fleet-journals` starts, or the fleet observability contract changes the journal reader's replay policy

`adopt-fleet-observability` selects the fleet `telemetry` and `node-exporter`
aspects on both workstations and ships host metrics to one declared
`fleet-metrics` destination. Journal shipping is a separate change
(`adopt-fleet-journals`), gated on accepted metrics adoption and on upstream
dispositions of the reader's replay policy and a provider health registration.

**Reason:** the two lanes were not equally settled. The metrics path is a
canonical remote-write destination plus a local loopback scrape, and the only
open questions are rollout evidence. Adopting journals at the same time would
have baked in an implicit history policy and an unreviewed privacy decision, and
nix-fleet is still reviewing both — so the split keeps the settled half moving
and leaves Vector unselected, which is also why no log data leaves either host
yet.

**Alternative:** adopt both lanes and fix the journal policy afterwards, or wait
for upstream on everything. The first would have made a default
(`current_boot_only`) into a decision nobody took; the second would have stalled
a lane that has no open questions.

## Forwarder health rides the transport it reports on

**Id:** cd095eb4-7e72-4afe-97c2-6f837097f8b6
**Type:** constraint
**Status:** active
**Evidence:** confirmed
**Revisit when:** the fleet provides a delivery-freshness signal, or central missing-data detection exists for these hosts

The contributor registers vmagent's own loopback metrics (`127.0.0.1:8429`) as a
scrape job so a forwarder that is running but failing to deliver is still
observable, and the port is asserted against the provider's own
`-httpListenAddr` rather than set independently — an array flag would add a
second listener.

This is self-health, not coverage: those samples travel the same queue they
describe, so a total transport outage hides its own evidence, and the pinned
vmagent exposes no last-successful-send age. A destination that accepts nothing
while the process stays up shows locally only as growing
`vmagent_remotewrite_pending_data_bytes` plus error counters. Detecting a silent
host is therefore central missing-data detection, and one that must tolerate a
laptop suspending rather than treating it as a server outage.
