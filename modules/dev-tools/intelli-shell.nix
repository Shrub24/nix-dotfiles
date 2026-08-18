_: {
  flake.modules.homeManager.intelli-shell =
    { ... }:
    {
      programs.intelli-shell = {
        enable = true;
        # Default integrations auto-enable for the shells the user has
        # (bash/zsh/fish); nushell integration is inert since nushell is off.
      };
    };
}
