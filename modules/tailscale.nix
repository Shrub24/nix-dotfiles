{ inputs, ... }:
{
  flake.modules.homeManager.tailscale =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.tailscale ];
    }

  ;

  # The fleet aspect owns the whole NixOS daemon side.
  flake.modules.nixos.tailscale = _: {
    imports = [
      inputs.nix-fleet.modules.nixos.tailscale

      # The aspect references sops.secrets inside `lib.mkIf`, and a condition guards
      # the value, not the reference — the option must exist with no auth key bound.
      inputs.sops-nix.nixosModules.sops
    ];

    # Tailnet-only: the ACL replaces authorized_keys on port 22; sshd keeps keys.
    # Disabling this drops the unit without running `tailscale set --ssh=false`.
    services.tailscale.sshServe = true;
  };
}
