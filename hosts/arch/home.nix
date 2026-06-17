{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules
  ];

  home.username = "saurabhj";
  home.homeDirectory = "/home/saurabhj";
  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = false;

  programs.home-manager.enable = true;

  programs.niks3 = {
    enableAutoUploadService = true;
  };

  programs.pi.enable = false;

  programs.litellm = {
    enable = true;
    headroom.enable = true;
  };
  programs.aichat = {
    enable = true;
    settings = {
      model = "litellm:coder";
      clients = [
        {
          type = "openai-compatible";
          name = "litellm";
          api_base = "http://localhost:8765/v1";
          api_key = "litellm-local";
          models = [
            {
              name = "coder";
              max_input_tokens = 131072;
            }
          ];
        }
      ];
    };
  };
  programs.lazyjournal = {
    enable = true;
    sshHosts = [
      "do-admin-1"
      "oci-melb-1"
    ];
  };
  programs.docsMcp.enable = true;
  programs.qmd.enable = true;
  programs.agentTools.enable = true;
  programs.devTools.enable = true;

  programs.agentmemory = {
    enable = true;
    hermesPlugin = {
      enable = true;
    };
    opencodePlugin = {
      enable = true;
    };
    settings = {
      AGENTMEMORY_TOOLS = "core";
      AGENTMEMORY_SLOTS = "true";
      AGENTMEMORY_REFLECT = "true";
      AGENTMEMORY_INJECT_CONTEXT = "true";
      CONSOLIDATION_ENABLED = "true";
      GRAPH_EXTRACTION_ENABLED = "true";
      EMBEDDING_PROVIDER = "openai";
      OPENAI_BASE_URL = "http://localhost:8765";
      OPENAI_EMBEDDING_MODEL = "embedding";
      OPENAI_EMBEDDING_DIMENSIONS = "4096";
      OPENAI_MODEL = "summariser";
    };
  };

  programs.hermes-agent.enable = true;

  programs.ssh.settings = {
    "oci-melb-1" = {
      HostName = "oci-melb-1";
      User = "dev";
    };
    "do-admin-1" = {
      HostName = "do-admin-1";
      User = "dev";
    };
  };

  programs.zsh.initContent = lib.mkAfter ''
    # Auto-attach tmux on remote (SSH/mosh) login
    if [[ -z "$TMUX" ]] && { [[ -n "$SSH_CONNECTION" ]] || [[ -n "$MOSH_SERVER" ]]; }; then
      exec tmux new-session -A -s main
    fi
  '';

  home.packages = with pkgs; [ marp-cli ];

  programs.miseTools = {
    enable = true;
    node = "lts";
    pnpm = "latest";
    bun = "latest";
  };

  # Bootstrap pi-telegram config from sops secret (one-shot, preserves runtime state)
  home.activation.piTelegramBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    TOKEN_FILE=${config.sops.secrets.telegram_bot_token.path}
    if [ ! -f ~/.pi/agent/telegram.json ] && [ -r "$TOKEN_FILE" ]; then
      run mkdir -p ~/.pi/agent
      run printf '{"botToken":"%s"}\n' "$(cat "$TOKEN_FILE")" > ~/.pi/agent/telegram.json
    fi
  '';
}
