_: {
  flake.modules.homeManager.chromium =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ ../../agents/_pi-mcp.nix ];

      programs.chromium = {
        enable = true;
        package = pkgs.chromium;
      };

      # The server drives this browser, so it takes the binary this aspect configures.
      programs.pi-coding-agent.mcpServers.chrome-devtools = {
        # Launched through npx, as mcp-nixos launches uvx: the version is pinned
        # here, and the package is fetched by npm rather than built by Nix.
        command = "npx";
        args = [
          "-y"
          "chrome-devtools-mcp@1.12.0"
          "--executablePath=${lib.getExe config.programs.chromium.package}"
          # A temporary profile leaves the user's running Chromium profile lock alone.
          "--isolated=true"
          # Telemetry is opt-out: usage statistics go to Google, and trace URLs
          # would go to the CrUX API.
          "--usageStatistics=false"
          "--performanceCrux=false"
        ];
        exposure = "deferred";
        description = "Chrome DevTools for browser automation: navigate, interact, screenshot, inspect console, network and performance traces.";
      };
    };
}
