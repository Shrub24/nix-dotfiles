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
in
{
  flake.modules.nixos.telemetry =
    { config, ... }:
    {
      imports = [ inputs.nix-fleet.modules.nixos.telemetry ];

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

        # Forwarder delivery health: vmagent's own loopback metrics, through
        # the same pipeline. The port is the fleet vmagent provider's own
        # `-httpListenAddr` (its telemetry contributor names no contract
        # option for it); `labels.instance` is explicit because the node
        # aspect's hostName:port default applies to its own registration only.
        scrape.vmagent-health = {
          target = "127.0.0.1";
          port = 8429;
          labels.instance = "${config.networking.hostName}:8429";
        };
      };
    };
}
