{
  inputs,
  system,
}:
let
  surge = inputs.surge.packages.${system}.default;
  # Truthful branch-build version derived from the locked input, never a
  # hardcoded release: upstream's package version is frozen at the stale 0.11.2
  # even on current main, so we use 0-unstable-<date>-<rev> instead.
  version = "0-unstable-${inputs.surge.lastModifiedDate}-${inputs.surge.shortRev}";
  # Upstream still links `-X main.version=` against a symbol that doesn't exist
  # (the real var is github.com/SurgeDM/Surge/cmd.Version), and pins its
  # vendorHash to an older nixpkgs Go. Both make the direct derivation wrong
  # (`surge --version` misreports provenance; a direct build fails). Rewrite the
  # flag to the real symbol with the derived version; drop this override when
  # upstream fixes its version flag + vendorHash.
  rewriteFlag =
    flag:
    if builtins.match ".*main\\.version=.*" flag == null then
      flag
    else
      (builtins.elemAt (builtins.split "main\\.version=" flag) 0)
      + "github.com/SurgeDM/Surge/cmd.Version=${version}";
in
surge.overrideAttrs (
  _: prev: {
    inherit version;
    __intentionallyOverridingVersion = true;
    ldflags = map rewriteFlag prev.ldflags;
    vendorHash = "sha256-Ei2i7dQ9s42Gg6f2iLABbTG7OQspjHoRnqIhkfcNvFo=";
  }
)
