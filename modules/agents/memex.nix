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

      # Upstream's `memex skill install` writes this file imperatively; declaring
      # it keeps the CLI-recall skill in the cross-tool directory, so the agent can
      # fall back to `memex search` when the MCP route is not the right tool.
      home.file.".agents/skills/memex-search/SKILL.md".source =
        "${inputs.memex.outPath}/skills/memex-search/SKILL.md";
    };
}
