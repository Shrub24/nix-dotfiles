{
  inputs,
  ...
}:
{
  # nix-fleet is the authority for the canonical fleet facts: machine identity,
  # target system, tailnet hostname and SSH host key. Importing the contract
  # brings in its typed schema, its inventory (home-forge, la-admin-1,
  # oci-melb-1, legion, spectre) and the pure projection API this repository
  # resolves against. Canonical facts are derived from here, never restated —
  # `topology.hosts` keeps only what is ours to own: the login user and the
  # account this repository configures.
  imports = [ inputs.nix-fleet.flakeModules.fleet ];

  # Which builders this repository's machines may hand work to. The canonical
  # `ci` profile is not ours to use: it schedules the metered nixbuild.net
  # resource, and it leaves home-forge unscoped, so every derivation would go
  # remote. Membership is the policy; there is no weight or predicate axis.
  #
  # The per-relationship job budget is the offload knob. nix's build hook
  # prefers any scheduled builder with a free slot and falls back to the local
  # machine only when none has one, so a small budget here is what pushes work
  # back onto the workstation. home-forge carries the ambient capacity for long
  # builds; the profile asks for more of it than the inventory's default.
  fleet.buildProfiles.workstations.hosts.home-forge = {
    maxJobs = 8;
  };

  # Until nix-homelab selects the build-account aspect on home-forge, the
  # `nixbuild` dispatch account the contract defaults to does not exist there,
  # so the builder still authorizes the interactive account. Drop this line
  # once the dispatch account is real.
  fleet.hosts.home-forge.capabilities.nixBuilder.endpoint.user = "dev";
}
