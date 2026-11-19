{ inputs, ... }:
{
  imports = [ inputs.nix-fleet.flakeModules.ci ];

  # Fleet posture, matching nix-homelab: three earlier roots behind the rolling pin.
  ci.retention.generations = 3;

  # A bump moves what the next switch deploys, so the update batch proposes
  # only: the operator picks the moment it lands, matching nix-homelab.
  ci.updates.autoMerge = false;
}
