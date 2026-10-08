# Selection is enablement: the fleet aspect owns the exporter, its
# loopback bind and its scrape registration. Metrics-only; no Home Manager
# aspect. The aspect names no backend — the host's selected telemetry
# implementation carries those metrics to the declared destination.
{ inputs, ... }:
{
  flake.modules.nixos.node-exporter =
    { ... }:
    {
      imports = [ inputs.nix-fleet.modules.nixos.node-exporter ];
    };
}
