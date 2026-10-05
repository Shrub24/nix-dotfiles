{ inputs, ... }: {
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.homeManager.sops-foundation = { config, pkgs, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    # Same age identity as the system scope.
    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # sops-nix's activation shells out to both; nothing here installs them otherwise.
    home.packages = [
      pkgs.age
      pkgs.sops
    ];
  };
}
