{ primaryUser }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.templates."aichat.env".content = ''
    LITELLM_API_KEY=${config.sops.placeholder.LITELLM_API_KEY}
  '';

  home = {
    username = primaryUser.name;
    homeDirectory = "/home/${primaryUser.name}";
    stateVersion = "26.11";
    enableNixpkgsReleaseCheck = false;

    sessionVariables.AICHAT_ENV_FILE = config.sops.templates."aichat.env".path;

    packages = with pkgs; [
      marp-cli
      (lib.mkIf config.targets.genericLinux.enable system-manager)
      byterover-cli
    ];
  };

  programs = {
    home-manager.enable = true;

    pi-coding-agent.enable = true;
    herdr.enable = true;

    litellm = {
      enable = true;
      database.enable = true;
      headroom.enable = false;
    };
    grist = {
      enable = true;
      administratorEmail = "jhanjeesaurabh@gmail.com";
      organizationSlug = "personal";
    };
    aichat = {
      enable = true;
      settings = {
        model = "litellm:coder";
        clients = [
          {
            type = "openai-compatible";
            name = "litellm";
            api_base = "http://localhost:${toString config.programs.litellm.port}/v1";
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
    lazyjournal = {
      enable = true;
    };
    docsMcp.enable = true;
    qmd.enable = true;
    agentTools.enable = true;
    devTools.enable = true;
    webCatalog.enable = true;

    hermes-agent.enable = true;

    zsh.initContent = lib.mkAfter ''
      if [[ -z "$TMUX" ]] && { [[ -n "$SSH_CONNECTION" ]] || [[ -n "$MOSH_SERVER" ]]; }; then
        exec tmux new-session -A -s main
      fi
    '';

    miseTools = {
      enable = true;
      node = "lts";
      pnpm = "latest";
      bun = "latest";
    };
  };

  services.hermes-agent = {
    enable = true;
    gateway.enable = true;
  };
}
