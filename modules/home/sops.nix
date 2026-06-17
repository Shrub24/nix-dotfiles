{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (lib) mkDefault;
  homeDir = config.home.homeDirectory;
  yamlSecrets = ../../secrets/agents.yaml;
in

{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    age.keyFile = "${homeDir}/.config/sops/age/keys.txt";

    # --- shell environment (generated from YAML-backed placeholders) ---
    templates."zsh-secrets.env".content = ''
      GITHUB_PAT=${config.sops.placeholder.GITHUB_PAT}
      GITHUB_TOKEN=${config.sops.placeholder.GITHUB_TOKEN}
      GEMINI_API_KEY=${config.sops.placeholder.GEMINI_API_KEY}
      CROFAI_API_KEY=${config.sops.placeholder.CROFAI_API_KEY}
      OPENROUTER_API_KEY=${config.sops.placeholder.OPENROUTER_API_KEY}
      OPENCODE_API_KEY=${config.sops.placeholder.OPENCODE_API_KEY}
      SOURCEGRAPH_TOKEN=${config.sops.placeholder.SOURCEGRAPH_TOKEN}
      TAVILY_API_KEY=${config.sops.placeholder.TAVILY_API_KEY}
      BRAVE_API_KEY=${config.sops.placeholder.BRAVE_API_KEY}
      FIRECRAWL_API_KEY=${config.sops.placeholder.FIRECRAWL_API_KEY}
      NEURALWATT_API_KEY=${config.sops.placeholder.NEURALWATT_API_KEY}
      CURSOR_API_KEY=${config.sops.placeholder.CURSOR_API_KEY}
      NIXBUILDNET_ACCESS_TOKENS=${config.sops.placeholder.NIXBUILDNET_ACCESS_TOKENS}
    '';

    # --- individual YAML-backed secrets ---

    secrets = {
      SOURCEGRAPH_TOKEN = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "sourcegraph_token";
      };
      GITHUB_PAT = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "github_pat";
      };
      GITHUB_TOKEN = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "github_token";
      };
      CROFAI_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "crofai_api_key";
      };
      OPENROUTER_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "openrouter_api_key";
      };
      OPENCODE_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "opencode_api_key";
      };
      JINA_TOKEN = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "jina_token";
      };
      TAVILY_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "tavily_api_key";
      };
      BRAVE_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "brave_api_key";
      };
      FIRECRAWL_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "firecrawl_api_key";
      };
      CONTEXT7_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "context7_api_key";
      };
      OPENAI_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "openai_api_key";
      };
      GEMINI_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "gemini_api_key";
      };

      DEEPSEEK_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "deepseek_api_key";
      };
      NEURALWATT_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "neuralwatt_api_key";
      };
      CURSOR_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "cursor_api_key";
      };

      NIXBUILDNET_ACCESS_TOKENS = {
        sopsFile = ../../secrets/nixbuild.yaml;
        format = "yaml";
        key = "nixbuildnet_access_token";
      };

      NIKS3_AUTH_TOKEN = {
        sopsFile = ../../secrets/niks3-secrets.yaml;
        format = "yaml";
        key = "niks3_auth_token";
      };

      # Pi telegram secret (remains in its own YAML file)
      telegram_bot_token.sopsFile = ../../secrets/pi-secrets.yaml;
    };

    # --- service output templates ---

    templates."docs-mcp.env".content = ''
      OPENAI_API_KEY=${config.sops.placeholder.OPENROUTER_API_KEY}
    '';

    templates."litellm.env" = {
      path = "${homeDir}/.config/litellm/.env";
      content = ''
        # litellm runtime secrets -- managed by sops
        GEMINI_API_KEY=${config.sops.placeholder.GEMINI_API_KEY}
        DEEPSEEK_API_KEY=${config.sops.placeholder.DEEPSEEK_API_KEY}
        CROFAI_API_KEY=${config.sops.placeholder.CROFAI_API_KEY}
        NEURALWATT_API_KEY=${config.sops.placeholder.NEURALWATT_API_KEY}
        OPENROUTER_API_KEY=${config.sops.placeholder.OPENROUTER_API_KEY}
        OPENCODE_API_KEY=${config.sops.placeholder.OPENCODE_API_KEY}
      '';
    };

    # nixbuild.net SSH config: passes access token via SetEnv
    templates."ssh-nixbuild-config" = {
      path = "${homeDir}/.ssh/config.d/10-nixbuild.net.conf";
      content = ''
        Host eu.nixbuild.net
          SetEnv NIXBUILDNET_ACCESS_TOKENS=${config.sops.placeholder.NIXBUILDNET_ACCESS_TOKENS}
      '';
    };

    # niks3 auth token for auto-upload post-build-hook
    templates."niks3-auth-token" = {
      path = "${homeDir}/.config/niks3/auth-token";
      content = config.sops.placeholder.NIKS3_AUTH_TOKEN;
    };
  };

  home.packages = [ pkgs.sops ];
}
