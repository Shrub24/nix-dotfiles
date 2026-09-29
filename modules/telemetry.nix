# Host-local telemetry contributor. nix-fleet owns the mechanism end to end: the
# `services.telemetry` contract, the orphan guard, and the private providers that
# realize it. This contributor exists so the selection is a local aspect name
# (registration is filesystem-driven, activation is host-driven) and so a host's
# registration policy has one place to live.
#
# Selection is enablement: importing the fleet module makes `services.telemetry`
# real on this host, which is what lets a consumer read `otlp.httpUrl`. Reading
# that on a host without this aspect fails closed by name, so the endpoint is
# only readable where a collector actually runs.
{ inputs, ... }:
{
  flake.modules.nixos.telemetry =
    { ... }:
    {
      imports = [ inputs.nix-fleet.modules.nixos.telemetry ];
    };
}
