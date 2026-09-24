# Observability agent contributor. The fleet aspect owns the mechanism end to
# end: the agent service, the notify registration, and the public key it
# verifies the hub with. This contributor is host policy only — where the
# agent's listener is reachable, and the hub key itself.
#
# The agent holds no secret. The KEY is the PUBLIC half of the hub's SSH
# keypair, so it is policy data rather than a sops secret, and there is no
# enrollment gate left to satisfy.
{ inputs, ... }:
{
  flake.modules.nixos.beszel-agent =
    { ... }:
    {
      imports = [ inputs.nix-fleet.modules.nixos.beszel-agent ];

      # Off until the hub's public key is bound: the hub runs on la-admin-1 and
      # has not published it. With the gate gone, enabling the agent without
      # the key would register a hub it cannot authenticate.
      services.beszel-agent = {
        enable = false;
        key = "";
      };

      # Metric egress stays tailnet-scoped: the hub lives behind the tailnet,
      # so the agent's listener follows the same closed-firewall convention as
      # the other services.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 45876 ];
    };
}
