{
  inputs,
  ...
}:
{
  imports = [ inputs.nix-fleet.flakeModules.fleet ];

  # Not the canonical `ci` profile: it schedules the metered nixbuild.net resource
  # and leaves home-forge unscoped, so every derivation would go remote.
  fleet.buildProfiles.workstations.hosts.home-forge = {
    maxJobs = 8;
  };

  # TODO: drop once nix-homelab selects the build-account aspect on home-forge —
  # the dispatch account the contract defaults to does not exist there yet.
  fleet.hosts.home-forge.capabilities.nixBuilder.endpoint.user = "dev";
}
