{ primaryUser }: _: {
  home = {
    username = primaryUser.name;
    homeDirectory = "/home/${primaryUser.name}";
    stateVersion = "26.11";
    enableNixpkgsReleaseCheck = false;
  };

  programs.home-manager.enable = true;

  programs.miseTools = {
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
