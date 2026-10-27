_: {
  flake.modules.homeManager.yazi =
    { lib, pkgs, ... }:
    {
      # Yazi and its plugins call these by name: `7zz` for archives, `ffmpeg` for
      # video frames (headless build: no GUI closure), `ouch` for compression,
      # `duckdb` for tabular previews and `jjui` for the jj interface.
      home.packages = [
        pkgs._7zz
        pkgs.duckdb
        pkgs.ffmpeg-headless
        pkgs.jjui
        pkgs.ouch
      ];

      programs.yazi = {
        enable = true;
        plugins = {
          piper = pkgs.yaziPlugins.piper;
          relative-motions = pkgs.yaziPlugins.relative-motions;
          ouch = pkgs.yaziPlugins.ouch;
          duckdb = {
            package = pkgs.yaziPlugins.duckdb;
            setup = true;
          };
          jjui = pkgs.yaziPlugins.jjui;
          time-travel = pkgs.yaziPlugins.time-travel;
          # Replaces the file(1) mime fetcher with an extension table in
          # init.lua; setup() swaps the preset fetchers itself.
          mime-ext = {
            package = pkgs.yaziPlugins.mime-ext;
            setup = true;
          };
          bookmarks = {
            package = pkgs.yaziPlugins.bookmarks;
            setup = true;
            settings.persist = "all";
          };
        };
        # Home Manager's own default for this block is mtime / reverse / dirs
        # first, but a module that sets anything under `settings` replaces that
        # default wholesale, so it is declared here. Yazi's built-in fallback is
        # unsorted, which is what the manager was showing.
        settings.mgr = {
          sort_by = "mtime";
          sort_reverse = true;
          sort_dir_first = true;
        };

        settings.plugin.prepend_previewers = [
          {
            url = "*.{md,markdown,mdx}";
            run = "piper -- pistol \"$1\"";
          }
          {
            mime = "application/{vnd.openxmlformats-officedocument.wordprocessingml.document,vnd.oasis.opendocument.text,epub+zip,rtf,x-sqlite3,vnd.sqlite3}";
            run = "piper -- pistol \"$1\"";
          }
          {
            url = "*.{csv,tsv,parquet,xlsx,duckdb}";
            run = "duckdb";
          }
        ];
        settings.plugin.prepend_preloaders = [
          {
            url = "*.{csv,tsv,parquet,xlsx,duckdb}";
            run = "duckdb";
            multi = false;
          }
        ];
        keymap.mgr.prepend_keymap = [
          # yazi 26 binds `z` to `plugin fzf` and `Z` to `plugin zoxide`, but
          # nixpkgs ships neither preset. A local plugin cannot stand in: yazi's
          # shell children get no controlling terminal (`tty` reports "not a
          # tty"), so fzf cannot draw, and `ui.hide()` — how the preset releases
          # the terminal — deadlocks when called directly and fails inside
          # `ya.sync`. What does work is yazi's own recursive search, which is
          # the same "find a path in this tree" job, filtered in-process.
          {
            on = [ "z" ];
            run = "search --via=fd";
            desc = "Search this tree by name";
          }
          {
            on = [ "C" ];
            run = "plugin ouch";
            desc = "Compress with ouch";
          }
          # `<`/`>` rather than a `g` pair: yazi's own `g h` is "Go home", and
          # shadowing it cost the built-in jump.
          {
            on = [ "<" ];
            run = "plugin duckdb -1";
            desc = "Scroll one column left";
          }
          {
            on = [ ">" ];
            run = "plugin duckdb +1";
            desc = "Scroll one column right";
          }
          # The XDG places, as yazi's docs suggest for bookmarks. The bookmarks
          # plugin keeps its list in Yazi's shared DDS state file, which is the
          # plugin's own to write. `g h` (home), `g c` (config) and `g d`
          # (downloads) are yazi's own defaults and stay unbound here.
          {
            on = [
              "g"
              "P"
            ];
            run = "cd ~/Projects";
            desc = "Go to ~/Projects";
          }
          {
            on = [
              "g"
              "D"
            ];
            run = "cd ~/Documents";
            desc = "Go to ~/Documents";
          }
          {
            on = [
              "g"
              "I"
            ];
            run = "cd ~/Pictures";
            desc = "Go to ~/Pictures";
          }
          {
            on = [
              "g"
              "M"
            ];
            run = "cd ~/Music";
            desc = "Go to ~/Music";
          }
          {
            on = [
              "g"
              "V"
            ];
            run = "cd ~/Videos";
            desc = "Go to ~/Videos";
          }
          {
            on = [
              "g"
              "J"
            ];
            run = "plugin jjui";
            desc = "Open jjui for this repository";
          }
          {
            on = [
              "T"
              "h"
            ];
            run = "plugin time-travel prev";
            desc = "Go to the previous snapshot";
          }
          {
            on = [
              "T"
              "l"
            ];
            run = "plugin time-travel next";
            desc = "Go to the next snapshot";
          }
          {
            on = [
              "T"
              "s"
            ];
            run = "plugin time-travel select";
            desc = "Select a snapshot";
          }
          {
            on = [
              "T"
              "e"
            ];
            run = "plugin time-travel exit";
            desc = "Stop browsing snapshots";
          }
          {
            on = [ "m" ];
            run = "plugin bookmarks save";
            desc = "Save current position as a bookmark";
          }
          {
            on = [ "'" ];
            run = "plugin bookmarks jump";
            desc = "Jump to a bookmark";
          }
          {
            on = [ "<C-k>" ];
            run = ''
              shell --
              	for p in %s; do kdeconnect-cli -n "$KDECONNECT_DEVICE" --share "$p"; done
            '';
            desc = "Send to phone via KDE Connect";
          }
          {
            on = [
              "b"
              "d"
            ];
            run = "plugin bookmarks delete";
            desc = "Delete a bookmark";
          }
        ]
        ++ map (n: {
          on = [ (toString n) ];
          run = "plugin relative-motions ${toString n}";
          desc = "Move in relative steps";
        }) (lib.range 1 9);
      };
    };
}
