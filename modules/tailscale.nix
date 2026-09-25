{ inputs, ... }:
{
  flake.modules.homeManager.tailscale =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.tailscale ];
    }

  ;

  flake.modules.systemManager.tailscale =
    { pkgs, ... }:
    {
      systemd.packages = [ pkgs.tailscale ];
      systemd.services.tailscaled = {
        wantedBy = [ "multi-user.target" ];
        environment.PORT = "41641";
      };
    }

  ;

  # The fleet aspect is the whole NixOS side: the daemon, the failure
  # registration, the MTU escape hatch, tailnet hostname pinning, and the
  # optional auth-key bootstrap.
  flake.modules.nixos.tailscale = _: {
    imports = [
      inputs.nix-fleet.modules.nixos.tailscale

      # The aspect references sops.secrets inside a `lib.mkIf`, and a condition
      # guards the value, not the reference — the option has to exist even on a
      # host that binds no auth key. The fleet documents sops-nix as a consumer
      # requirement; declaring it beside the aspect keeps the dependency where
      # it arises instead of making every host carry it.
      inputs.sops-nix.nixosModules.sops
    ];

    # Tailscale SSH intercepts port 22 from the tailnet and serves a host key
    # derived from the node key, not from /etc/ssh/ssh_host_*. Peers that pin
    # us in ssh_known_hosts would see a changed key, so this host's trust model
    # — pinned host keys, projected from the fleet inventory — needs it off.
    # Turning it on moves tailnet SSH auth to the ACLs and invalidates every
    # peer's pin of this host.
    services.tailscale.sshServe = false;
  };
}
