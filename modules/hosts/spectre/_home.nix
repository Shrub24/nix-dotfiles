{ primaryUser }: _: {
  # Imported inside the composition's `home-manager.users.<name>` list, so these
  # are Home Manager options directly.
  home = {
    username = primaryUser.name;
    homeDirectory = "/home/${primaryUser.name}";
    stateVersion = "26.11";
    enableNixpkgsReleaseCheck = false;
  };

  programs.home-manager.enable = true;

  # Journal picker over ssh; the aspect is option-gated, so the host turns it on.
  programs.lazyjournal.enable = true;

  # Same dev stack as the desktop, minus services. The other aspects are
  # unconditional; `miseTools` is what turns on the mise aspect.
  programs.miseTools = {
    enable = true;
    node = "lts";
    pnpm = "latest";
    bun = "latest";
  };

  # Reattach the shared tmux session on login so a dropped link loses nothing.
  programs.fish.interactiveShellInit = ''
    if test -z "$TMUX"; and begin; set -q SSH_CONNECTION; or set -q MOSH_SERVER; end
      exec tmux new-session -A -s main
    end
  '';
}
