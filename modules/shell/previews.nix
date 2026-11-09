_: {
  flake.modules.homeManager.previews =
    { lib, pkgs, ... }:
    let
      # A picture is the slowest preview here: chafa needs ~300 ms for a
      # 12-megapixel photo and ~230 ms for a complex SVG, and a full-resolution
      # transfer costs the same. So the source is decoded once at the pane's
      # size — vectors with resvg, large photos with magick — and every rendering
      # is cached by source identity and geometry.
      previewImage = pkgs.writeShellApplication {
        name = "previewImage";
        runtimeInputs = with pkgs; [
          chafa
          coreutils
          gnused
          imagemagick
          kitty
          resvg
        ];
        text = ''
          # fzf exports its pane, piper exports `w`/`h`: either consumer sizes the image.
          cols=''${FZF_PREVIEW_COLUMNS:-''${w:-80}}
          rows=''${FZF_PREVIEW_LINES:-''${h:-40}}
          cache=''${XDG_CACHE_HOME:-$HOME/.cache}/preview-images
          mkdir -p "$cache"
          key=$(printf '%s|%s|%sx%s' "$1" "$(stat -c '%Y.%s' "$1")" "$cols" "$rows" | md5sum | cut -d' ' -f1)

          # chafa's own SVG rasteriser ignores the pane and costs three times a
          # resvg pass, which also draws the result like any other picture.
          scaled="$cache/$key.png"
          if ! test -f "$scaled"; then
            case "$1" in
              *.svg | *.svgz) resvg --width $((cols * 8)) "$1" "$scaled" >/dev/null 2>&1 ;;
              *)
                if test "$(stat -c %s "$1")" -gt 1500000; then
                  magick "$1" -resize "$((cols * 8))x$((rows * 16))>" "$scaled" >/dev/null 2>&1
                fi
                ;;
            esac
            test -f "$scaled" || rm -f "$scaled"
          fi
          test -f "$scaled" && src="$scaled" || src="$1"

          # A protocol-capable terminal draws the picture itself: kitty, and the
          # compatible implementations that carry the same environment.
          graphics=""
          case "''${KITTY_WINDOW_ID:-}''${KITTY_PID:-}''${KITTY_LISTEN_ON:-}''${HERDR_PANE_ID:-}" in
            ?*) graphics=1 ;;
          esac
          case "''${TERM_PROGRAM:-}''${TERM:-}" in
            *[Ww]e[Zz][Tt]erm* | *[Gg]hostty* | *kitty*) graphics=1 ;;
          esac

          rendered="$cache/$key.symbols.ans"
          if test -n "$graphics"; then
            # Only icat's unicode placeholders survive fzf's repaint, so the
            # trailing reset code, which arrives without a newline, is folded on
            # (fzf reads a missing newline as a scroll offset).
            if ! {
              kitten icat --clear --transfer-mode=memory --unicode-placeholder \
                --stdin=no --place="''${cols}x''${rows}@0x0" "$src" \
                | sed '$d' | sed $'$s/$/\e[m/'
            }; then
              test -f "$rendered" || chafa -f symbols --size="''${cols}x''${rows}" "$src" >"$rendered" 2>/dev/null
              cat "$rendered"
              echo
            fi
          else
            # Outside a graphics terminal chafa picks the best available format.
            rendered="$cache/$key.auto.ans"
            test -f "$rendered" || chafa --size="''${cols}x''${rows}" "$src" >"$rendered" 2>/dev/null
            cat "$rendered"
            echo
          fi
        '';
      };
      previewMarkdown = pkgs.writeShellApplication {
        name = "previewMarkdown";
        runtimeInputs = with pkgs; [
          glow
          gnused
        ];
        text = ''
          width=''${w:-''${FZF_PREVIEW_COLUMNS:-100}}
          glow -w="$width" "$1" | sed -E 's/\x1B]8;[^\x07]*\x07//g'
        '';
      };
      previewPdf = pkgs.writeShellApplication {
        name = "previewPdf";
        runtimeInputs = with pkgs; [
          poppler-utils
          bat
          coreutils
        ];
        text = ''
          if test -n "''${FZF_PREVIEW_COLUMNS:-}"; then
            page="$(mktemp --suffix=.png)"
            trap 'rm -f "$page"' EXIT
            if pdftoppm -f 1 -l 1 -r 96 -png -singlefile "$1" "''${page%.png}"; then
              ${lib.getExe previewImage} "$page"
              exit
            fi
          fi

          pdftotext -layout "$1" - \
            | head -n "''${h:-''${FZF_PREVIEW_LINES:-100}}" \
            | bat -l md --color=always --style=plain
        '';
      };
      previewDuckdb = pkgs.writeShellApplication {
        name = "previewDuckdb";
        runtimeInputs = with pkgs; [ duckdb ];
        text = ''
          rows=''${h:-''${FZF_PREVIEW_LINES:-20}}
          case "$1" in
            *.parquet) duckdb -c "select * from read_parquet('$1') limit $rows" ;;
            *.duckdb | *.db) duckdb -readonly "$1" -c ".tables" -c ".schema" ;;
            *) duckdb -c "select * from '$1' limit $rows" ;;
          esac
        '';
      };
    in
    {
      # Pistol serves fzf's shell preview and yazi's piper; the converters it
      # dispatches to are named here so both consumers resolve them.
      home.packages = with pkgs; [
        chafa
        fontconfig
        glow
        duckdb
        hexyl
        jaq
        mediainfo
        pandoc
        poppler-utils
        sqlite
      ];

      programs.pistol = {
        enable = true;

        # `sh:` is what makes pistol run the command through a shell, so pipes and
        # `$w`/`$h` reach the previewer: piper exports the pane size as `w`/`h`,
        # fzf exports its own as FZF_PREVIEW_COLUMNS/LINES. The first matching
        # pattern wins, so the specific text types precede `text/*`.
        associations = [
          {
            fpath = ".*\\.(md|markdown)$";
            command = "${lib.getExe previewMarkdown} %pistol-filename%";
          }
          {
            fpath = ".*\\.(parquet|duckdb)$";
            command = "${lib.getExe previewDuckdb} %pistol-filename%";
          }
          {
            fpath = ".*\\.(ttf|otf|woff2?)$";
            command = ''sh: fc-scan --format "%{family}\\n%{style}\\n%{fullname}\\n%{fontversion}\\n%{file}\\n" %pistol-filename%'';
          }
          {
            mime = "text/(csv|tab-separated-values)";
            command = ''sh: column -s, -t %pistol-filename% | head -n "''${h:-''${FZF_PREVIEW_LINES:-100}}" | cut -c1-"''${w:-''${FZF_PREVIEW_COLUMNS:-200}}"'';
          }
          {
            mime = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
            command = ''sh: timeout 5 pandoc -t plain --columns="''${w:-''${FZF_PREVIEW_COLUMNS:-100}}" %pistol-filename%'';
          }
          {
            mime = "application/vnd.oasis.opendocument.text";
            command = ''sh: timeout 5 pandoc -t plain --columns="''${w:-''${FZF_PREVIEW_COLUMNS:-100}}" %pistol-filename%'';
          }
          {
            mime = "application/epub+zip";
            command = ''sh: timeout 5 pandoc -t plain --columns="''${w:-''${FZF_PREVIEW_COLUMNS:-100}}" %pistol-filename%'';
          }
          {
            mime = "application/rtf";
            command = ''sh: timeout 5 pandoc -t plain --columns="''${w:-''${FZF_PREVIEW_COLUMNS:-100}}" %pistol-filename%'';
          }
          {
            mime = "application/(vnd\\.|x-)sqlite3";
            command = "sqlite3 %pistol-filename% .schema";
          }
          {
            mime = "text/*";
            command = "bat --color=always --line-range=:500 %pistol-filename%";
          }
          {
            mime = "application/json";
            command = ''sh: jaq -C -S . %pistol-filename% 2>/dev/null | head -n "''${h:-''${FZF_PREVIEW_LINES:-100}}"'';
          }
          {
            mime = "image/*";
            command = "${lib.getExe previewImage} %pistol-filename%";
          }
          {
            mime = "application/pdf";
            command = "${lib.getExe previewPdf} %pistol-filename%";
          }
          {
            mime = "audio/*";
            command = "mediainfo %pistol-filename%";
          }
          {
            mime = "application/(x-executable|x-pie-executable|x-sharedlib|x-object|octet-stream)";
            command = "hexyl -n 512 %pistol-filename%";
          }
          {
            mime = "inode/directory";
            command = ''sh: eza --tree --icons --level=2 --color=always %pistol-filename% | head -n "''${h:-''${FZF_PREVIEW_LINES:-100}}"'';
          }
          {
            mime = "inode/symlink";
            command = "eza -l --color=always --icons %pistol-filename%";
          }
          {
            mime = "inode/*";
            command = "file -b %pistol-filename%";
          }
        ];
      };
    };
}
