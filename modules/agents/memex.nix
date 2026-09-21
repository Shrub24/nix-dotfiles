{ inputs, ... }:
{
  # Shrub24/memex@deploy/live: upstream's derivation needs manual
  # ORT_LIB_PATH/ORT_PREFER_DYNAMIC_LINK overrides to build; this branch wraps
  # the binary with ORT_DYLIB_PATH and carries the Home Manager module used here.
  flake-file.inputs.memex.url = "github:Shrub24/memex/deploy/live";

  # Indexes local agent history (Claude Code, Codex, OpenCode, Pi) for search,
  # transcript reads and session resume.
  flake.modules.homeManager.memex =
    { pkgs, ... }:
    {
      imports = [ inputs.memex.homeManagerModules.default ];

      programs.memex = {
        enable = true;
        # nixpkgs carries no memex, so the fork supplies binary and wrapper.
        package = inputs.memex.packages.${pkgs.stdenv.hostPlatform.system}.default;
        daemon.enable = true;

        settings.auto_index_on_search = true;
      };

      # The CLI-recall skill ships with pi's skills directory (vendored from the
      # fork into modules/agents/pi/skills/memex-search); ~/.agents is an
      # out-of-store symlink, so home.file cannot write into it.
    };
}
