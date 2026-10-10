_: {
  # Aspect `gtk`: the GTK settings surface. Kept apart from `kde-apps` because
  # the coupling between them is one setting — Qt takes its icon theme from
  # GTK 3 — not a shared concern.
  flake.modules.homeManager.gtk =
    { config, ... }:
    {
      gtk = {
        enable = true;
        gtk2.enable = false;

        # Only the icon theme is owned: colourScheme stays unset because the
        # dconf write it would add fights the live GTK theme and scheme, which
        # Noctalia owns.
        iconTheme.name = "Sweet-Rainbow";

        # The Places sidebar of GTK file dialogs, over the same standard
        # directories `xdg.userDirs` declares. GTK saves an edit made through a
        # chooser by writing a temporary file and renaming it over this path,
        # which replaces the store symlink with a real file; the next switch
        # restores the declared list and moves the edit aside as a backup.
        gtk3.bookmarks = map (dir: "file://${config.home.homeDirectory}/${dir}") [
          "Documents"
          "Music"
          "Pictures"
          "Videos"
          "Downloads"
        ];
      };
    };

  flake.modules.nixos.gtk = _: {
    # The Home Manager half writes the GTK icon theme to dconf, and dconf
    # activation fails on NixOS without this — the D-Bus name is not activatable.
    programs.dconf.enable = true;
  };
}
