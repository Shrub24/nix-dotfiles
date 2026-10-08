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
}
