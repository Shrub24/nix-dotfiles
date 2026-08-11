{
  inputs,
}:
let
  surge = inputs.surge.packages.x86_64-linux.default;
in
surge.overrideAttrs (final: prev: {
  version = "0.11.2";
  __intentionallyOverridingVersion = true;
  # Upstream's `-X main.version=` targets a nonexistent symbol (the real
  # variable is cmd.Version), so `surge --version` would print "Surge vdev".
  # Rewrite the version linker flag to the correct symbol and version.
  ldflags = map (f: builtins.replaceStrings [ "main.version=0.8.5" ] [ "github.com/SurgeDM/Surge/cmd.Version=0.11.2" ] f) prev.ldflags;
  # vendorHash is pinned for upstream's own nixpkgs; following this repo's
  # nixpkgs changes the Go version and therefore the vendored output.
  vendorHash = "sha256-uZrSOcwfXJ9LwuHi+0wIjPBIsAdULU60GbWrJNV923s=";
})
