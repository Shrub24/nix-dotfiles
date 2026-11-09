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
  # Rendered preview in a float, tab or split; not in nixpkgs.
  md-render-nvim = fromGitHub {
    owner = "delphinus";
    repo = "md-render.nvim";
    rev = "977c8e4fd73bd1656836c87895458a54098920ba"; # v3.9.0
    hash = "sha256-goOv3ePoMv8anl4MZOGVkz285rtk4eB5oIT6Sm7+wh0=";
  };

  # Neovim does not ship spell files and would download them on first `set spell`.
  spell-en = pkgs.runCommand "nvim-spell-en" { } ''
    mkdir -p $out/spell
    cp ${
      pkgs.fetchurl {
        url = "https://ftp.nluug.nl/pub/vim/runtime/spell/en.utf-8.spl";
        hash = "sha256-/sq9yUm2o50ywImfolReqyXmPy7QozxK0VEUJjhNMHA=";
      }
    } $out/spell/en.utf-8.spl
    cp ${
      pkgs.fetchurl {
        url = "https://ftp.nluug.nl/pub/vim/runtime/spell/en.utf-8.sug";
        hash = "sha256-W25eYWVYLS/Xob+kH7zoJCxyR2IixV0XwqorqTPJMuw=";
      }
    } $out/spell/en.utf-8.sug
  '';

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
