# Observability agent contributor. The fleet aspect owns the mechanism end to
# end: the agent service, the notify registration, and the key the agent
# verifies the hub with. This contributor is host policy only — the hub's
# public key, and where the agent's listener is reachable.
#
# The agent holds no secret. The KEY is the PUBLIC half of the hub's SSH
# keypair, so it is policy data rather than a sops secret, and there is no
# enrollment gate to satisfy. TOKEN is deliberately not wired upstream: the
# WebSocket registration path needs plain-HTTP reachability of the hub, and
# the hub sits behind Cloudflare Access while agents reach it over tailnet SSH.
{ inputs, ... }:
{
  flake.modules.nixos.beszel-agent =
    { ... }:
    {
      imports = [ inputs.nix-fleet.modules.nixos.beszel-agent ];

      # The hub runs on la-admin-1; this is its public half.
      services.beszel-agent = {
        enable = true;
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILETioYsZkau/yIH2LocWZP3d7z0nZAKIMb2POQNEhst";
      };

      # Metric egress stays tailnet-scoped: the hub lives behind the tailnet,
      # so the agent's listener follows the same closed-firewall convention as
      # the other services.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 45876 ];
    };
}
