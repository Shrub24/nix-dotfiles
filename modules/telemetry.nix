# Selection is enablement: importing the fleet module is what makes
# `services.telemetry` readable here; consumers elsewhere fail closed by name.
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
        otlp.signals = [ "traces" ];
      };
    };
}
