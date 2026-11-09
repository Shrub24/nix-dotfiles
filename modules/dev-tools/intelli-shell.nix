{
  config,
  inputs,
  ...
}:
let
  omniroute = "${
    inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
      service = "omniroute";
      endpoint = "api";
      via = "tailnet";
    }
  }/v1";

  catalogEntry = model: {
    provider = "openai";
    inherit model;
    url = omniroute;
    api_key_env = "OMNIROUTE_API_KEY";
  };
in
{
  flake.modules.homeManager.intelli-shell = _: {
    programs.intelli-shell = {
      enable = true;
      # nushell integration is inert; nushell is off.
      #
      # Fish 4 rejects the Fish 3 compatibility branch in the generated script
      # (`bind \c$char`) as invalid syntax, and `source` discards the whole
      # file, so the integration is sourced with that branch rewritten to Fish
      # 4 key names. HACK: drop once upstream stops emitting the escape form.
      enableFishIntegration = false;

      settings.ai = {
        enabled = true;
        models = {
          suggest = "coder-high";
          fix = "coder-high";
          import = "coder-high";
          completion = "budget";
          fallback = "budget";
        };
        catalog = {
          coder-high = catalogEntry "coder-high";
          budget = catalogEntry "budget";
        };
      };
    };
    programs.fish.interactiveShellInit = ''
      intelli-shell init fish \
        | string replace 'bind \c$char $target_func' 'bind ctrl-$char $target_func' \
        | string replace 'bind \e$char $target_func' 'bind alt-$char $target_func' \
        | source
    '';
  };
}
