{ config, inputs, ... }:
let
  # Resolved at the flake-parts level from the fleet's service inventory, like
  # modules/notify.nix: NixOS modules cannot read flake-level config.fleet.
  metricsRemoteWriteUrl = inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
    service = "victoriametrics";
    endpoint = "remote-write";
    via = "tailnet";
  };
  # The AI ingress, not the general one: Pi's sessions belong in the
  # LLM-observability backends, which the general ingress does not fan out to.
  tracesGatewayUrl = inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
    service = "otel-collector";
    endpoint = "ai-otlp";
    via = "tailnet";
  };
in
{
  flake.modules.nixos.telemetry =
    { ... }:
    {
      imports = [
        inputs.nix-fleet.modules.nixos.telemetry-metrics
        inputs.nix-fleet.modules.nixos.telemetry-otlp
      ];

      services.telemetry = {
        # The one explicitly selected metrics destination. The backend
        # coordinates stay canonical: a catalogue URL change needs a
        # queue-continuity review, not a local edit.
        destinations.fleet-metrics = {
          protocol = "prometheus-remote-write";
          endpoint = metricsRemoteWriteUrl;
          signals = [ "metrics" ];
        };
        # Pinned so a later destination cannot silently fan host metrics out.
        pipelines.metrics = [ "fleet-metrics" ];
        destinations.fleet-traces = {
          protocol = "otlp-http";
          endpoint = tracesGatewayUrl;
          signals = [ "traces" ];
        };
        pipelines.traces = [ "fleet-traces" ];
        # Metrics are admitted too, but only ever reach the metrics destination:
        # `pipelines.metrics` is pinned to the remote-write endpoint above, so
        # the LLM backends behind the trace gateway are out of reach by
        # construction, not by policy.
        otlp.signals = [
          "traces"
          "metrics"
        ];
      };

      # Pi's metric series carry their host only as a resource attribute, which
      # the remote-write exporter drops into the `target_info` series unless it
      # is promoted to a label. The scrape lane labels its series `host`.
      services.otel-collector.exporterExtra.fleet-metrics.resource_to_telemetry_conversion.enabled = true;
    };
}
