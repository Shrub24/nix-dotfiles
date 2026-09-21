_: {
  flake.modules.nixos.containers = _: {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;

      # nixpkgs defines the `podman-prune` unit unconditionally (its ExecStart is
      # not gated on autoPrune), so nix-fleet's `podman-prune` aspect cannot
      # coexist with it — the platform unit is the one to configure. Grist
      # bind-mounts its state, so --volumes only reclaims unused volumes.
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [
          "--all"
          "--force"
          "--volumes"
        ];
      };
    };
  };
}
