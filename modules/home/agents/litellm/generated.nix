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
        sha256 = "sha256-pgMmJ08jSV8EvCxX7iRkuoGQ/q1HeRRC1NXa3qgxOmA=";
      }
    )
  );

  registryLookup = builtins.mapAttrs (_: m: {
    context_length = m.limit.context or null;
    max_output = m.limit.output or null;
    input_modalities = m.modalities.input or null;
    output_modalities = m.modalities.output or null;
  }) modelRegistry;

  defaultContext = 128000;
  defaultOutput = 16384;
  defaultModalities = {
    input = [ "text" ];
    output = [ "text" ];
  };

  resolveRegistryMeta =
    ids:
    let
      idList = if builtins.isString ids then [ ids ] else ids;
      findFirstValid =
        list:
        if list == [ ] then
          { }
        else
          let
            head = builtins.head list;
            tail = builtins.tail list;
            entry = registryLookup.${head} or { };
          in
          if entry.context_length != null && entry.max_output != null then entry else findFirstValid tail;
    in
    findFirstValid idList;

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

  routeGroupName =
    routeName: chainIndex:
    if chainIndex == 0 then routeName else "${routeName}__fallback${toString chainIndex}";

  modelEntries = lib.flatten (
    lib.mapAttrsToList (
      aliasName: routeName:
      let
        route = routes.${routeName};
      in
      lib.imap0 (chainIndex: deployment: {
        model_name = routeGroupName aliasName chainIndex;
        litellm_params = mkParams deployment;
        model_info = {
          mode = route.mode;
          id = "${routeName}__${deployment.upstream}";
        };
      }) route.chain
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
  };

  opencodeModels = lib.mapAttrs (
    _: model:
    let
      meta = resolveRegistryMeta (model.registryModel or [ ]);
    in
    {
      name = model.name;
      limit = {
        context = meta.context_length or defaultContext;
        output = meta.max_output or defaultOutput;
      };
      modalities = {
        input = meta.input_modalities or defaultModalities.input;
        output = meta.output_modalities or defaultModalities.output;
      };
    }
    // lib.optionalAttrs (model.autogenerateVariants or false) {
      variants = mkVariants;
    }
  ) clientModels;
in
{
  inherit
    aliases
    clientModels
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
        type = "remote";
        url = "http://127.0.0.1:${toString headroomPort}/mcp";
        enabled = true;
      };
    };
  };
}
