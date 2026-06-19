{
  lib,
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
      routeName: route:
      lib.imap0 (chainIndex: deployment: {
        model_name = routeGroupName routeName chainIndex;
        litellm_params = mkParams deployment;
        model_info = {
          mode = route.mode;
          id = "${routeName}__${deployment.upstream}";
        };
      }) route.chain
    ) routes
  );

  fallbackMappings = lib.flatten (
    lib.mapAttrsToList (
      routeName: route:
      let
        chainLength = builtins.length route.chain;
      in
      lib.genList (
        chainIndex:
        if chainIndex + 1 < chainLength then
          {
            "${routeGroupName routeName chainIndex}" = [ (routeGroupName routeName (chainIndex + 1)) ];
          }
        else
          { }
      ) chainLength
    ) routes
  );

  mkVariants = {
    none = {
      reasoningEffort = "none";
      reasoningSummary = "auto";
      textVerbosity = "medium";
    };
    low = {
      reasoningEffort = "low";
      reasoningSummary = "auto";
      textVerbosity = "medium";
    };
    medium = {
      reasoningEffort = "medium";
      reasoningSummary = "auto";
      textVerbosity = "medium";
    };
    high = {
      reasoningEffort = "high";
      reasoningSummary = "detailed";
      textVerbosity = "medium";
    };
    xhigh = {
      reasoningEffort = "xhigh";
      reasoningSummary = "detailed";
      textVerbosity = "medium";
    };
  };

  opencodeModels = lib.mapAttrs (
    _: model:
    {
      name = model.name;
      limit = {
        context = model.context;
        output = model.output;
      };
      modalities = {
        input = model.inputModalities;
        output = model.outputModalities;
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
    litellm_settings = {
      drop_params = true;
    };
    router_settings = {
      routing_strategy = "simple-shuffle";
      fallbacks = builtins.filter (mapping: mapping != { }) fallbackMappings;
      model_group_alias = aliases;
    };
  };

  opencodeExtraConfig = {
    "$schema" = "https://opencode.ai/config.json";
    provider = {
      "${providerLabel}" = {
        npm = "@ai-sdk/openai-compatible";
        name = "LiteLLM";
        options = {
          baseURL = "http://localhost:8765/v1";
        };
        models = opencodeModels;
      };
    };
  };
}
