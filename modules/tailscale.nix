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

    # Tailscale SSH claims port 22 for the tailnet IP only: tailscaled generates
    # its own host key pair, publishes the public half through the control
    # plane, and rewrites the client's known_hosts just-in-time, so rotation is
    # invisible. sshd and authorized_keys are untouched, which keeps
    # non-tailnet connections — the LAN, and the nix builder paths — on keys.
    # What moves is the tailnet answer to "who can log in": the ACL replaces
    # authorized_keys there, and SSH auth is `none`, so no key is presented.
    #
    # The flag is applied by nixpkgs' tailscaled-set oneshot, which exists only
    # while extraSetFlags is non-empty. Turning this off therefore removes the
    # unit without running `tailscale set --ssh=false` — that part is manual.
    services.tailscale.sshServe = true;
  };
}
