# Shared user-scoped credentials, one secret file per consumer group so a host
# decrypts only what its selected aspects consume. Each entry needs only the
# file and the YAML key: format defaults to yaml, path to
# ~/.config/sops-nix/secrets/<name>, owner/mode to the invoking user at 0400.
#
# Consumers read these two ways. Where the tool has a native key mechanism it
# points at the decrypted secret path — pi providers and pi-web-access use
# `!cat <path>`, MCP headers `!command`, magic-context `{file:...}` — so the
# value never enters the environment. Everything else is exported by the
# `agent-env.env` template below, and only for keys whose consumer can read
# nothing but the environment.
_: {
  flake.modules.homeManager.credentials =
    { config, ... }:

    let
      secretsDir = ../../secrets;

      mkSecrets =
        file:
        builtins.mapAttrs (
          _name: key: {
            sopsFile = file;
            inherit key;
          }
        );
    in

    {
      sops = {
        secrets =
          mkSecrets (secretsDir + "/llm-providers.yaml") {
            OMNIROUTE_API_KEY = "omniroute_api_key";
            OMNIROUTE_MANAGEMENT_KEY = "omniroute_management_key";
            TYPESAFE_API_KEY = "typesafe_api_key";
            NEURALWATT_API_KEY = "neuralwatt_api_key";
            OPENROUTER_API_KEY = "openrouter_api_key";
            OPENCODE_API_KEY = "opencode_api_key";
            DEEPSEEK_API_KEY = "deepseek_api_key";
            CURSOR_API_KEY = "cursor_api_key";
            VOLCENGINE_API_KEY = "volcengine_api_key";
            TOKENROUTER_API_KEY = "tokenrouter_api_key";
          }
          // mkSecrets (secretsDir + "/web-search.yaml") {
            BRAVE_API_KEY = "brave_api_key";
            TAVILY_API_KEY = "tavily_api_key";
            JINA_TOKEN = "jina_token";
            PARALLEL_API_KEY = "parallel_api_key";
            TINYFISH_API_KEY = "tinyfish_api_key";
            SERPDIVE_API_KEY = "serpdive_api_key";
            FIRECRAWL_API_KEY = "firecrawl_api_key";
            GEMINI_API_KEY = "gemini_api_key";
            DATALAB_API_KEY = "datalab_api_key";
          }
          // mkSecrets (secretsDir + "/github.yaml") {
            GITHUB_PAT = "github_pat";
            GITHUB_TOKEN = "github_token";
          }
          // mkSecrets (secretsDir + "/sourcegraph.yaml") {
            SOURCEGRAPH_TOKEN = "sourcegraph_token";
          };

        # Environment for tools that cannot be pointed at a file. Every line
        # names its env-only consumer; delete a line when that consumer gains a
        # key mechanism.
        templates."agent-env.env".content = ''
          OMNIROUTE_API_KEY=${config.sops.placeholder.OMNIROUTE_API_KEY}
          NEURALWATT_API_KEY=${config.sops.placeholder.NEURALWATT_API_KEY}
          OPENROUTER_API_KEY=${config.sops.placeholder.OPENROUTER_API_KEY}
          OPENCODE_API_KEY=${config.sops.placeholder.OPENCODE_API_KEY}
          GITHUB_TOKEN=${config.sops.placeholder.GITHUB_TOKEN}
          BRAVE_API_KEY=${config.sops.placeholder.BRAVE_API_KEY}
          DATALAB_API_KEY=${config.sops.placeholder.DATALAB_API_KEY}
        '';
      };
    };
}
