{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Import from non-flake source to avoid checks.nix syntax error
  upstreamModule =
    (import "${inputs.hermes-agent-src}/nix/homeManagerModules.nix" {
      inherit inputs;
    }).flake.homeManagerModules.default;
in
{
  imports = [ upstreamModule ];

  programs.hermes-agent = {
    enable = lib.mkDefault false;
    package = lib.mkDefault inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
    environmentFiles = [
      config.sops.templates."hermes.env".path
    ];
    mcpServers = lib.mkMerge [
      (lib.mkIf (config.programs.docsMcp.enable or false) {
        docs = {
          url = "http://localhost:${toString config.programs.docsMcp.port}/mcp";
        };
      })
      (lib.mkIf (config.programs.qmd.enable or false) {
        qmd = {
          url = "http://localhost:${toString config.programs.qmd.port}/mcp";
        };
      })
    ];
    settings = lib.mkDefault {
      model = {
        provider = "custom";
        base_url = "http://localhost:8765/v1";
        default = "main";
      };
      platform_toolsets.cli = [
        "web"
        "terminal"
        "file"
        "memory"
        "todo"
        "skills"
      ];
      agent = {
        max_turns = 40;
        api_max_retries = 1;
        gateway_timeout = 600;
        disabled_toolsets = [
          "browser"
          "vision"
          "image_gen"
          "moa"
          "tts"
          "cronjob"
          "session_search"
          "skills_hub"
        ];
      };
      auxiliary = {
        compression = {
          provider = "main";
          model = "summariser";
        };
        web_extract = {
          provider = "main";
          model = "explorer";
        };
      };
      terminal = {
        backend = "local";
        timeout = 120;
      };
      approvals = {
        mode = "smart";
        cron_mode = "deny";
      };
      compression = {
        enabled = true;
        threshold = 0.7;
        target_ratio = 0.25;
        protect_first_n = 1;
        protect_last_n = 10;
      };
      tool_loop_guardrails = {
        warnings_enabled = true;
        hard_stop_enabled = true;
      };
      session_reset.mode = "none";
      display = {
        compact = true;
        tool_progress = "new";
        show_reasoning = false;
      };
      prompt_caching.cache_ttl = "1h";
      tool_output = {
        max_bytes = 35000;
        max_lines = 1500;
        max_line_length = 1500;
      };
      stt.enabled = false;
      lsp.enabled = false;
      checkpoints.enabled = false;
      skills.creation_nudge_interval = 0;
      memory = {
        nudge_interval = 0;
        memory_char_limit = 1200;
        user_char_limit = 800;
      };
    };
  };
}
