{
  config,
  inputs,
  ...
}:
let
  # Resolved at the flake-parts level from the fleet's canonical service inventory.
  niks3ServerUrl = inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
    service = "niks3-write";
    endpoint = "api";
    via = "tailnet";
  };
in
{
  flake.modules.nixos.niks3 = _: {
    # nix-fleet owns the mechanism; this binds the server URL and the token.
    # sops-nix is the fleet aspect's documented consumer requirement, not a choice.
    imports = [
      inputs.nix-fleet.modules.nixos.niks3-publisher
      inputs.sops-nix.nixosModules.sops
    ];

    services.niks3-publisher = {
      serverUrl = niks3ServerUrl;
      secretFiles.apiToken = ../secrets/niks3-secrets.yaml;
      secretKeys.apiToken = "niks3_auth_token";
    };
  };
}
