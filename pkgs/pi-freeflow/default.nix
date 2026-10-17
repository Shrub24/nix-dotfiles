# pi-freeflow registers the free-model catalogue and spawns a shared proxy
# daemon from its own sources, so it loads at runtime rather than compiling into
# Pi-Bolt. This package carries the one compat correction that relay pool needs
# and vendors the dependency that correction's neighbour imports; see build.py.
{
  runCommand,
  fetchurl,
  python3,
}:
let
  version = "1.38.2";
  package = fetchurl {
    url = "https://registry.npmjs.org/pi-freeflow/-/pi-freeflow-${version}.tgz";
    hash = "sha512-csI3YzDJsVA0kuPe+vniZukGRU9mwkxTc1RpLDDumarnL6RD4aIa/tlMGUFQqCJI1WUHz1XOUuHB7yzQw3gkrQ==";
  };
  undici = fetchurl {
    url = "https://registry.npmjs.org/undici/-/undici-7.30.0.tgz";
    hash = "sha512-dkrQXeHSaoamnItlYbmzG0wFYrM0ZwDxCIg0A7aKjTyyhh9svRzCNFEzV+Vm05/yehjCzjDZ31KXfGEjYSztDQ==";
  };
in
runCommand "pi-freeflow-${version}" { inherit package undici; } ''
  ${python3}/bin/python3 ${./build.py}
''
