# Observability agent contributor. The fleet aspect owns the mechanism end to
# end — two-step sops gate, KEY/TOKEN environment template, agent service, and
# the failure registration shared with the notify capability. This contributor
# is host policy only: which secret files carry the fleet-wide key and the
# host-scoped enrollment token, and where the agent port is reachable. No
# secret file, no agent: the gate keeps the first unsecrets install evaluating.
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

      # Metric egress stays tailnet-scoped: the hub lives behind the tailnet,
      # so the agent's listener follows the same closed-firewall convention as
      # the other services.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 45876 ];
    };
}
