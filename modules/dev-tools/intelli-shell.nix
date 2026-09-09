_: {
  flake.modules.homeManager.intelli-shell = _: {
    programs.intelli-shell = {
      enable = true;
      # nushell integration is inert; nushell is off.
    };
  };
}
