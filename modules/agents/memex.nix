{ inputs, ... }:
{
  # Shrub24/memex@deploy/live: upstream's derivation needs manual
  # ORT_LIB_PATH/ORT_PREFER_DYNAMIC_LINK overrides to build; this branch wraps
  # the binary with ORT_DYLIB_PATH and carries the Home Manager module used here.
  flake-file.inputs.memex = {
    url = "github:Shrub24/memex/deploy/live";
    inputs.nixpkgs.follows = "nixpkgs";
    # rust-overlay carries a whole second nixpkgs; only its lib is used here.
    inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

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

        settings = {
          auto_index_on_search = true;

          # Serving MCP is what makes the service continuous — the module picks
          # `daemon run` over `index` whenever this is set — so one process
          # holds the index and the embedding model resident and pi dials it,
          # instead of every session spawning its own stdio server and loading
          # a second copy of the model (the default model is local gemma).
          #
          # The listen address is stated rather than left to the 127.0.0.1:5363
          # default so the URL pi builds cannot drift from an upstream default
          # change without this file moving too.
          index_service_mcp = true;
          mcp.listen = "127.0.0.1:5363";
        };
      };

      # The CLI-recall skill ships with pi's skills directory (vendored from the
      # fork into modules/agents/pi/skills/memex-search); ~/.agents is an
      # out-of-store symlink, so home.file cannot write into it.
    };
}
