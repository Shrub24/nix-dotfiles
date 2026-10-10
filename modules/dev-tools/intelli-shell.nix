_: {
  flake.modules.homeManager.intelli-shell = _: {
    programs.intelli-shell = {
      enable = true;
      # nushell integration is inert; nushell is off.
      #
      # Fish 4 rejects the Fish 3 compatibility branch in the generated script
      # (`bind \c$char`) as invalid syntax, and `source` discards the whole
      # file, so the integration is sourced with that branch rewritten to Fish
      # 4 key names. Drop this once upstream stops emitting the escape form.
      enableFishIntegration = false;
    };
    programs.fish.interactiveShellInit = ''
      intelli-shell init fish \
        | string replace 'bind \c$char $target_func' 'bind ctrl-$char $target_func' \
        | string replace 'bind \e$char $target_func' 'bind alt-$char $target_func' \
        | source
    '';
  };
}
