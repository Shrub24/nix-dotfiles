{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    defaultSopsFile = ../../secrets/zsh-secrets.env;

    secrets."zsh-secrets-env" = {
      format = "dotenv";
      path = "${config.home.homeDirectory}/.secrets/zsh-secrets.env";
    };
  };

  home.packages = [ pkgs.sops ];
}
