# Plugins nixpkgs does not package, pinned by revision so the versions are
# reproducible. The in-tree sops module is not one: it is config Lua at
# nvim/lua/sops_nvim, resolved from the config runtimepath.
{ pkgs }:
let
  inherit (pkgs.vimUtils) buildVimPlugin;

  fromGitHub =
    {
      owner,
      repo,
      rev,
      hash,
      ...
    }@args:
    buildVimPlugin {
      pname = repo;
      version = builtins.substring 0 7 rev;
      src = pkgs.fetchFromGitHub (
        {
          inherit
            owner
            repo
            rev
            hash
            ;
        }
        // builtins.removeAttrs args [
          "owner"
          "repo"
          "rev"
          "hash"
        ]
      );
    };
in
{
  herdr-nvim = fromGitHub {
    owner = "ChmaraX";
    repo = "herdr-nvim";
    rev = "0450dc7b4c40c986052541c00dba5cdcd1be7ac6";
    hash = "sha256-KpcNuX0I0N5oFzjsLpZV59SYVzaNO8j1+kDtBG2bK5Y=";
  };

  vim-slime-cells = fromGitHub {
    owner = "klafyvel";
    repo = "vim-slime-cells";
    rev = "2252bc83fc0174c8e67bcf9a519edf2d328b8bc9";
    hash = "sha256-d3+uH+LuIbrBFNp5BCHca2m94RN2asGgzQojC2f6yoQ=";
  };

  pick-resession-nvim = fromGitHub {
    owner = "scottmckendry";
    repo = "pick-resession.nvim";
    rev = "3bd9b6a7765be068d2bd88ba77c2602229c97442";
    hash = "sha256-q6HHHn1PP/NXg9yk00IUJiThNcgvqlSq4xUbAfeojok=";
  };
}
