_: {
  flake.modules.nixos.containers = _: {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;

      # nixpkgs defines the `podman-prune` unit unconditionally, so nix-fleet's aspect
      # cannot coexist. Grist bind-mounts its state, so --volumes is safe.
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
