{
  flake.modules.nixos.containers =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.podman-compose ];

      # `registries.registry` only declares a registry; short names need this list.
      virtualisation.containers.registries.settings."unqualified-search-registries" = [ "docker.io" ];

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
