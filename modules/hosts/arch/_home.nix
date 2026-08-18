{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Host-local remote hosts list (B11), matching arch.nix topology.
  sshHosts = [
    "oci-melb-1"
    "do-admin-1"
    "la-admin-1"
  ];
in
{
  # aichat owns its env template (cross-module placeholder from credentials).
  sops.templates."aichat.env".content = ''
    LITELLM_API_KEY=${config.sops.placeholder.LITELLM_API_KEY}
  '';

  home = {
    # Host-local literals at the host composition layer (B4/B11).
    username = "saurabhj";
    homeDirectory = "/home/saurabhj";
    stateVersion = "26.11";
    enableNixpkgsReleaseCheck = false;

    sessionVariables.AICHAT_ENV_FILE = config.sops.templates."aichat.env".path;

    packages = with pkgs; [
      marp-cli
      system-manager
      byterover-cli
    ];
  };

  programs = {
    home-manager.enable = true;

    niks3 = {
      enableAutoUploadService = true;
    };

    pi.enable = false;

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
      sshHosts = sshHosts;
    };
    docsMcp.enable = true;
    qmd.enable = true;
    agentTools.enable = true;
    devTools.enable = true;
    webCatalog.enable = true;

    hermes-agent.enable = true;

    zsh.initContent = lib.mkAfter ''
      # Auto-attach tmux on remote (SSH/mosh) login
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

  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };
}
