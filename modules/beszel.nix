# Observability agent contributor. nix-fleet owns the Beszel agent enrollment
# mechanism (two-step sops gate, KEY/TOKEN environment template, agent service);
# this contributor binds the repository's secret files — the fleet-wide agent
# key in secrets/beszel.yaml (key beszel/key) and the host-scoped enrollment
# token (key hosts/<id>/beszel-token) — and registers the unit's failure with
# the fleet's notify capability. No secret file, no agent: the two-step gate
# keeps the first unsecrets install evaluating.
{ inputs, lib, ... }:
{
  flake.modules.nixos.beszel-agent =
    { config, ... }:
    let
      hostId = config.currentHost.id;
      hostSecret = ../secrets/hosts + "/${hostId}/beszel.yaml";
      hasHostSecret = builtins.pathExists hostSecret;
    in
    {
      imports = [ inputs.nix-fleet.modules.nixos.beszel-agent ];

      services.beszel-agent.secretFiles = {
        common = ../secrets/beszel.yaml;
        host = lib.mkIf hasHostSecret hostSecret;
      };

      # The registration must not precede the unit: the fleet's fail-closed
      # validation rejects events for services that don't exist, and the agent
      # only materialises once the host-scoped enrollment token is present.
      services.notify.events."beszel-agent" = lib.mkIf hasHostSecret {
        failure = { };
      };

      # Metric egress stays tailnet-scoped: the hub lives behind the tailnet,
      # so the agent's listener follows the same closed-firewall convention as
      # the other services.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 45876 ];
    };
}
