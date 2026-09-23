_: {
  flake.modules.homeManager.tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.agentTools;
    in
    {
      options.programs.agentTools = {
        enable = lib.mkEnableOption "AI agent CLI tools (codebase-memory-mcp, xberg-cli)";
      };

      config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
          brave-search-cli
          codebase-memory-mcp
          xberg-cli
        ];

        # A package bump must retire running instances: clients spawn the MCP
        # server per session and cbm detaches its own internal daemon, so an old
        # store path stays alive next to the new one and the mix fails. Kill all
        # instances only when the store path actually changed; the next MCP call
        # respawns the fresh binary. Stamped so ordinary switches stay silent.
        home.activation.codebaseMemoryRefresh = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          stamp="${config.xdg.stateHome}/codebase-memory-mcp/store-path"
          current="${pkgs.codebase-memory-mcp}"
          if [ "$(cat "$stamp" 2>/dev/null || true)" != "$current" ]; then
            ${pkgs.procps}/bin/pkill -f '(^|/)codebase-memory-mcp( |$)' 2>/dev/null || true
            mkdir -p "$(dirname "$stamp")"
            printf '%s' "$current" > "$stamp"
          fi
        '';
      };
    };

}
