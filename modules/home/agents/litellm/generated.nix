{
  lib,
  headroomEnable ? false,
  headroomPort ? 8787,
}:

let
  config = import ./aliases.nix;
  inherit (config)
    aliases
    clientModels
    routes
    upstreams
    ;
  providerLabel = "litellm";

  # ── Model metadata from models.dev ──────────────────────────────────

  modelRegistry = builtins.fromJSON (
    builtins.readFile (
      builtins.fetchurl {
        url = "https://models.dev/models.json";
        sha256 = "sha256-6e/r7w1vMUi6CCYOhFBm2c3HOTXD87NNkdKXQCe9exQ=";
      }
    )
  );

  defaultContext = 128000;
  defaultOutput = 16384;
  defaultModalities = {
    input = [ "text" ];
    output = [ "text" ];
  };

  # ponytail: accept one registry id string; caller already validates type
  resolveRegistryMeta = id: modelRegistry.${id} or { };

  # ── LiteLLM config generation ──────────────────────────────────────

  mkProviderModel =
    deployment:
    let
      upstream = upstreams.${deployment.upstream};
    in
    if upstream.providerFamily == "openai" then
      "openai/${deployment.model}"
    else
      "${upstream.providerFamily}/${deployment.model}";

  mkParams =
    deployment:
    let
      upstream = upstreams.${deployment.upstream};
      base = {
        model = mkProviderModel deployment;
        api_key = "os.environ/${upstream.apiKeyEnv}";
      };
    in
    base // lib.optionalAttrs (upstream ? apiBase) { api_base = upstream.apiBase; };

  # ponytail: string chain entry = upstream name; model defaults to the route key
  normalizeEntry =
    routeName: entry:
    if builtins.isString entry then
      {
        upstream = entry;
        model = routeName;
      }
    else
      entry;

  routeGroupName =
    routeName: chainIndex:
    if chainIndex == 0 then routeName else "${routeName}__fallback${toString chainIndex}";

  modelEntries = lib.flatten (
    lib.mapAttrsToList (
      aliasName: routeName:
      let
        route = routes.${routeName};
      in
      lib.imap0 (
        chainIndex: rawEntry:
        let
          deployment = normalizeEntry routeName rawEntry;
        in
        {
          model_name = routeGroupName aliasName chainIndex;
          litellm_params = mkParams deployment;
          model_info = {
            mode = route.mode;
            id = "${routeName}__${deployment.upstream}";
          };
        }
      ) route.chain
    ) aliases
  );

  fallbackMappings = lib.flatten (
    lib.mapAttrsToList (
      aliasName: routeName:
      let
        route = routes.${routeName};
        chainLength = builtins.length route.chain;
      in
      lib.genList (
        chainIndex:
        if chainIndex + 1 < chainLength then
          {
            "${routeGroupName aliasName chainIndex}" = [ (routeGroupName aliasName (chainIndex + 1)) ];
          }
        else
          { }
      ) chainLength
    ) aliases
  );

  mkVariants = {
    none = {
      reasoningEffort = "none";
      textVerbosity = "medium";
    };
    low = {
      reasoningEffort = "low";
      textVerbosity = "medium";
    };
    medium = {
      reasoningEffort = "medium";
      textVerbosity = "medium";
    };
    high = {
      reasoningEffort = "high";
      textVerbosity = "medium";
    };
    xhigh = {
      reasoningEffort = "xhigh";
      textVerbosity = "medium";
    };
    max = {
      reasoningEffort = "max";
      textVerbosity = "medium";
    };
  };

  mkHeadroomModel = aliasName:
    let
      routeName = aliases.${aliasName} or aliasName;
      route =
        routes.${routeName} or (throw "clientModel '${aliasName}': route '${routeName}' does not exist");
      registryModel =
        route.registryModel
          or (throw "clientModel '${aliasName}': route '${routeName}' lacks registryModel");
      meta =
        if builtins.isString registryModel then
          resolveRegistryMeta registryModel
        else
          throw "clientModel '${aliasName}': registryModel is ${builtins.typeOf registryModel}, expected string";
      limit_ = meta.limit or { };
      modalities_ = meta.modalities or { };
    in
    {
      limit = {
        context = limit_.context or defaultContext;
        output = limit_.output or defaultOutput;
      };
      modalities = {
        input = modalities_.input or defaultModalities.input;
        output = modalities_.output or defaultModalities.output;
      };
      inherit registryModel;
    };

  opencodeModels = lib.mapAttrs (
    aliasName: model:
    mkHeadroomModel aliasName
    // {
      name = model.name;
    }
    // lib.optionalAttrs (model.autogenerateVariants or false) {
      variants = mkVariants;
    }
  ) clientModels;

  # ── Headroom 0.27 context-limit catalog ─────────────────────────────
  # ponytail: minimal OpenAI-compatible provider namespace; no pricing (not in source metadata)
  headroomCatalog = {
    openai = {
      context_limits = lib.mapAttrs (_: model: model.limit.context) headroomModels;
    };
  };
  headroomModels = lib.mapAttrs (aliasName: _: mkHeadroomModel aliasName) aliases;
  headroomModelAliasMap = lib.mapAttrs (_: model: model.registryModel) headroomModels;
in
{
  inherit
    aliases
    clientModels
    headroomCatalog
    headroomModelAliasMap
    opencodeModels
    providerLabel
    routes
    upstreams
    ;

  litellmConfig = {
    model_list = modelEntries;
    general_settings = {
      store_prompts_in_spend_logs = true;
      store_model_in_db = true;
    };
    litellm_settings = {
      callbacks = [ "arize_phoenix" ];
      drop_params = true;
    };
    environment_variables = {
      PHOENIX_COLLECTOR_ENDPOINT = "http://oci-melb-1:4317";
    };
    # guardrails injected below via optionalAttrs
    router_settings = {
      routing_strategy = "simple-shuffle";
      fallbacks = builtins.filter (mapping: mapping != { }) fallbackMappings;
    };
  }
  // lib.optionalAttrs headroomEnable {
    guardrails = [
      {
        guardrail_name = "headroom-compression";
        litellm_params = {
          guardrail = "headroom";
          mode = "pre_call";
          api_base = "http://127.0.0.1:${toString headroomPort}";
          default_on = true;
        };
      }
    ];
  };

  opencodeExtraConfig = {
    "$schema" = "https://opencode.ai/config.json";
    provider = {
      "${providerLabel}" = {
        npm = "@ai-sdk/openai-compatible";
        name = "LiteLLM";
        options = {
          baseURL = "http://localhost:8765/v1";
          apiKey = "{env:OPENCODE_LITELLM_API_KEY}";
        };
        models = opencodeModels;
      };
    };
  }
  // lib.optionalAttrs headroomEnable {
    mcp = {
      headroom = {
        type = "local";
        command = "headroom";
        args = [
          "mcp"
          "serve"
          "--proxy-url"
          "http://127.0.0.1:${toString headroomPort}"
        ];
        enabled = true;
      };
    };
  };
}
