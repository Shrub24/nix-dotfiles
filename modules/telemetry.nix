# Selection is enablement: importing the fleet module is what makes
# `services.telemetry` readable here; consumers elsewhere fail closed by name.
{ inputs, ... }:
{
  flake.modules.nixos.telemetry =
    { ... }:
    {
      imports = [ inputs.nix-fleet.modules.nixos.telemetry ];
    };
}
