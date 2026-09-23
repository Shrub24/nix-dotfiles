{ omniroute, primaryUser }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.templates."aichat.env".content = ''
    OMNIROUTE_API_KEY=${config.sops.placeholder.OMNIROUTE_API_KEY}
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

    grist = {
      enable = true;
      administratorEmail = "jhanjeesaurabh@gmail.com";
      organizationSlug = "personal";
    };
    aichat = {
      enable = true;
      settings = {
        model = "omniroute:coder-high";
        clients = [
          {
            type = "openai-compatible";
            name = "omniroute";
            api_base = "${omniroute}/v1";
            models = [
              {
                name = "coder-high";
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

    hermes-agent.enable = false;

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
