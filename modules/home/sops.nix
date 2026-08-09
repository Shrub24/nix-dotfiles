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
      OPENROUTER_API_KEY=${config.sops.placeholder.OPENROUTER_API_KEY}
      OPENCODE_API_KEY=${config.sops.placeholder.OPENCODE_API_KEY}
      SOURCEGRAPH_TOKEN=${config.sops.placeholder.SOURCEGRAPH_TOKEN}
      TAVILY_API_KEY=${config.sops.placeholder.TAVILY_API_KEY}
      BRAVE_API_KEY=${config.sops.placeholder.BRAVE_API_KEY}
      FIRECRAWL_API_KEY=${config.sops.placeholder.FIRECRAWL_API_KEY}
      NEURALWATT_API_KEY=${config.sops.placeholder.NEURALWATT_API_KEY}
      CURSOR_API_KEY=${config.sops.placeholder.CURSOR_API_KEY}
      LITELLM_API_KEY=${config.sops.placeholder.LITELLM_API_KEY}
      LITELLM_MASTER_KEY=${config.sops.placeholder.LITELLM_MASTER_KEY}
      OPENCODE_LITELLM_API_KEY=${config.sops.placeholder.OPENCODE_LITELLM_API_KEY}
      OPENAI_COMPATIBLE_API_KEY=${config.sops.placeholder.LITELLM_API_KEY}
      VOLCENGINE_API_KEY=${config.sops.placeholder.VOLCENGINE_API_KEY}
    '';

    # --- individual YAML-backed secrets ---

    secrets = {
      VOLCENGINE_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "volcengine_api_key";
      };
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
      # CROFAI_API_KEY = {
      #   sopsFile = yamlSecrets;
      #   format = "yaml";
      #   key = "crofai_api_key";
      # };
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

      LITELLM_MASTER_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "litellm_master_key";
      };

      LITELLM_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "litellm_api_key";
      };

      LITELLM_DATABASE_PASSWORD = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "litellm_database_password";
      };

      OPENCODE_LITELLM_API_KEY = {
        sopsFile = yamlSecrets;
        format = "yaml";
        key = "opencode_litellm_api_key";
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
      OPENAI_API_KEY=${config.sops.placeholder.LITELLM_API_KEY}
    '';

    templates."hermes.env".content = ''
      OPENAI_API_KEY=${config.sops.placeholder.LITELLM_API_KEY}
    '';

    templates."aichat.env".content = ''
      LITELLM_API_KEY=${config.sops.placeholder.LITELLM_API_KEY}
    '';

    templates."litellm.env" = {
      path = "${homeDir}/.config/litellm/.env";
      content = ''
        # litellm runtime secrets -- managed by sops
        LITELLM_MASTER_KEY=${config.sops.placeholder.LITELLM_MASTER_KEY}
        ${lib.optionalString config.programs.litellm.database.enable "DATABASE_URL=postgresql://litellm:${config.sops.placeholder.LITELLM_DATABASE_PASSWORD}@oci-melb-1:5432/litellm?sslmode=disable"}
        ${lib.optionalString config.programs.litellm.headroom.enable "HEADROOM_API_BASE=http://127.0.0.1:${toString config.programs.litellm.headroomPort}"}
        GEMINI_API_KEY=${config.sops.placeholder.GEMINI_API_KEY}
        DEEPSEEK_API_KEY=${config.sops.placeholder.DEEPSEEK_API_KEY}
        NEURALWATT_API_KEY=${config.sops.placeholder.NEURALWATT_API_KEY}
        VOLCENGINE_API_KEY=${config.sops.placeholder.VOLCENGINE_API_KEY}
        OPENROUTER_API_KEY=${config.sops.placeholder.OPENROUTER_API_KEY}
        OPENCODE_API_KEY=${config.sops.placeholder.OPENCODE_API_KEY}
      '';
    };

    # nixbuild.net access token for nix-daemon (symlinked from system-manager)
    templates."nixbuild.net.env" = {
      path = "${homeDir}/.config/nix/nixbuild.net.env";
      content = ''
        NIXBUILDNET_ACCESS_TOKENS=${config.sops.placeholder.NIXBUILDNET_ACCESS_TOKENS}
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
