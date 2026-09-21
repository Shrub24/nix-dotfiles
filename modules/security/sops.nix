{ inputs, ... }: {
  flake-file.inputs.sops-nix.url = "github:Mic92/sops-nix";

  flake.modules.homeManager.sops-foundation = { config, pkgs, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    # The age identity uses same key as the system scope (single host today).
    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Safety belt for shell activation; sops-nix's activation shells out to these.
    home.packages = [
      pkgs.age
      pkgs.sops
    ];
  };
}
