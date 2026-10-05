{ inputs, ... }:
{
  # TOKEN is deliberately not wired: the registration path needs plain-HTTP
  # reachability of the hub, which sits behind Cloudflare Access.
  flake.modules.nixos.beszel-agent =
    { ... }:
    {
      imports = [ inputs.nix-fleet.modules.nixos.beszel-agent ];

      # The hub runs on la-admin-1; this is its public half.
      services.beszel-agent.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILETioYsZkau/yIH2LocWZP3d7z0nZAKIMb2POQNEhst";

      # Tailnet-scoped, like the other services: the hub lives behind the tailnet.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 45876 ];
    };
}
