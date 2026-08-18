_:
{
  flake.modules.homeManager.credentials =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      yamlSecrets = ../../../secrets/agents.yaml;
    in

    {
      # Shared, genuinely cross-feature LLM/provider credentials from
      # secrets/agents.yaml, plus the shell-wide agent/dev env template.
      sops = {
        templates = {
          "zsh-secrets.env".content = ''
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
        };

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
        };
      };
    }
  ;
}
