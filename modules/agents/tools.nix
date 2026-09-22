{ inputs, ... }:
{
  flake-file.inputs = {
    codebase-memory-mcp = {
      url = "github:DeusData/codebase-memory-mcp/v0.11.0";
      # Keeps its own nixpkgs: a version-pinned Rust tool, not a churn follower.
      inputs.nixpkgs.autoFollow = false;
    };
  };

  flake.modules.homeManager.tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.agentTools;
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      options.programs.agentTools = {
        enable = lib.mkEnableOption "AI agent CLI tools (codebase-memory-mcp, xberg-cli, cass)";

        cass.skill = {
          enable = lib.mkEnableOption "cass SKILL.md into the skills directory";
          dir = lib.mkOption {
            type = lib.types.str;
            default = ".agents/skills";
            description = "Home-relative directory to symlink the cass skill into";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
          brave-search-cli
          inputs.codebase-memory-mcp.packages.${system}.default
          xberg-cli
          # cass disabled 2026-09-20: superseded by memex for session recall
          # (modules/agents/memex.nix); derivation + nvfetcher source kept for
          # quick re-enable.
        ];

        # A package bump must retire running instances: clients spawn the MCP
        # server per session and cbm detaches its own internal daemon, so an old
        # store path stays alive next to the new one and the mix fails. Kill all
        # instances only when the store path actually changed; the next MCP call
        # respawns the fresh binary. Stamped so ordinary switches stay silent.
        home.activation.codebaseMemoryRefresh = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          stamp="${config.xdg.stateHome}/codebase-memory-mcp/store-path"
          current="${inputs.codebase-memory-mcp.packages.${system}.default}"
          if [ "$(cat "$stamp" 2>/dev/null || true)" != "$current" ]; then
            ${pkgs.procps}/bin/pkill -f '(^|/)codebase-memory-mcp( |$)' 2>/dev/null || true
            mkdir -p "$(dirname "$stamp")"
            printf '%s' "$current" > "$stamp"
          fi
        '';
      };
    };

}
