{
  inputs,
  ...
}:
{
  # nix-fleet owns the pin: its nixbot input drives the fleet's federated CI,
  # so one nix-fleet update moves the server contract and this CLI together.
  flake-file.inputs.nixbot.follows = "nix-fleet/nixbot";

  flake.modules.homeManager.nixbot =
    { pkgs, ... }:
    {
      home.packages = [
        # Enrol repositories in the fleet's nixbot instance: the instance facts
        # come from nix-fleet's canonical inventory, so the operator installs it
        # and configures nothing.
        inputs.nix-fleet.packages.${pkgs.stdenv.hostPlatform.system}.ci-enrol
        # The `nbo` client; the token stays in the environment (NIXBOT_TOKEN,
        # credentials aspect), never in hosts.toml.
        inputs.nixbot.packages.${pkgs.stdenv.hostPlatform.system}.nixbot-cli
      ];

      # `nbo` picks a server by matching the checkout's origin remote against
      # each entry's remotes patterns (host/owner/repo, shell wildcards).
      xdg.configFile."nixbot/hosts.toml".source =
        (pkgs.formats.toml { }).generate "nixbot-hosts.toml" {
          "https://nixbot.shrublab.xyz".remotes = [ "github.com/Shrub24/*" ];
        };
    };
}
