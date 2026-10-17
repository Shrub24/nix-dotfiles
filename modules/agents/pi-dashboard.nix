_: {
  flake.modules.homeManager.pi-dashboard =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.piDashboard;
      homepage = import ../../lib/web-services.nix { inherit lib; };
      seed = import ../../lib/seed-json.nix { inherit pkgs; };
      # The extension row declares this package; Pi's own package manager
      # materialises it in the agent directory, so the service runs the
      # installed copy rather than a second one built here.
      server = "${config.home.homeDirectory}/.pi/agent/npm/node_modules/@blackbelt-technology/pi-agent-dashboard/packages/server/bin/pi-dashboard.mjs";
      dashboardConfig = builtins.toJSON {
        inherit (cfg) port piPort;
        # The bridge only attaches. It cannot spawn this server on a host where
        # pi is a Bun binary: it picks a TypeScript loader for a Node it never
        # resolves and would run the pi binary as the interpreter.
        autoStart = false;
        tunnel.enabled = false;
        agentPathGate.enabled = false;
        gitWorktreeEnabled = false;
        plugins =
          lib.genAttrs
            [
              "apple-tools"
              "automation"
              "blackhole"
              "browser"
              "chat-gateway"
              "cost-estimator"
              "flows"
              "flows-anthropic-bridge"
              "gmail"
              "goal"
              "grammar"
              "hermes-memory"
              "kb"
              "keycloak-resolver"
              "mcp-client"
              "mcp-server"
              "quota"
              "roles"
              "subagents"
              "system-one"
              "team"
            ]
            (_: {
              enabled = false;
            });
        bindHost = "0.0.0.0";
        trustedNetworks = [ "100.64.0.0/10" ];
      };
    in
    {
      options.programs.piDashboard = {
        port = lib.mkOption {
          type = lib.types.port;
          default = homepage.services.pi-dashboard.port;
          description = "HTTP and browser WebSocket port for the dashboard.";
        };

        piPort = lib.mkOption {
          type = lib.types.port;
          default = 9999;
          description = "Port the dashboard's pi gateway serves bridge sessions on.";
        };
      };

      config = {
        systemd.user.services.pi-dashboard = {
          Unit = {
            Description = "Pi Dashboard — web UI over local pi sessions";
            # Nothing to serve until Pi has installed the package the row names.
            ConditionPathExists = server;
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            Type = "exec";
            ExecStart = "${lib.getExe pkgs.nodejs_22} ${server} --port ${toString cfg.port} --pi-port ${toString cfg.piPort}";
            Restart = "on-failure";
            RestartSec = "10s";
            StandardOutput = "journal";
            StandardError = "journal";
          };

          Install = {
            WantedBy = [ "default.target" ];
          };
        };

        home.activation.piDashboardConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          seed ".pi/dashboard/config.json" dashboardConfig
        );
      };
    };
}
