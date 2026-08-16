{
  writeShellScriptBin,
  nix-search-tv,
  fzf,
}:

writeShellScriptBin "nstv" ''
    export PATH="${nix-search-tv}/bin:${fzf}/bin:$PATH"

    CMD="nix-search-tv"

    SEARCH_SNIPPET_KEY="ctrl-w"
    OPEN_SOURCE_KEY="ctrl-s"
    OPEN_HOMEPAGE_KEY="ctrl-o"
    NIX_SHELL_KEY="ctrl-i"
    PRINT_PREVIEW_KEY="ctrl-p"

    OPENER="xdg-open"

    STATE_FILE="/tmp/nix-search-tv-fzf"

    SEARCH_SNIPPET_CMD='echo "{}"'
    SEARCH_SNIPPET_CMD="$SEARCH_SNIPPET_CMD | tr -d \"\'\" "
    SEARCH_SNIPPET_CMD="$SEARCH_SNIPPET_CMD | awk '{ if (\$2) { print \$2 } else print \$1 }' "
    SEARCH_SNIPPET_CMD="$SEARCH_SNIPPET_CMD | xargs printf \"https://github.com/search?type=code&q=lang:nix+%s\" \$1 "

    NIX_SHELL_CMD='nix-shell --run $SHELL -p $(echo "{}" | sed "s:nixpkgs/::g"'
    NIX_SHELL_CMD="$NIX_SHELL_CMD | tr -d \"\'\")"

    echo "" > "$STATE_FILE"

    HEADER="$OPEN_HOMEPAGE_KEY - open homepage
  $OPEN_SOURCE_KEY - open source
  $SEARCH_SNIPPET_KEY - search github for snippets
  $NIX_SHELL_KEY - nix-shell
  $PRINT_PREVIEW_KEY - print preview
  "

    fzf_args=(
      --preview "$CMD preview \$(cat $STATE_FILE) {}"

      --bind "$OPEN_SOURCE_KEY:execute($CMD source \$(cat $STATE_FILE) {} | xargs $OPENER)"
      --bind "$OPEN_HOMEPAGE_KEY:execute($CMD homepage \$(cat $STATE_FILE) {} | xargs $OPENER)"
      --bind "$SEARCH_SNIPPET_KEY:execute($SEARCH_SNIPPET_CMD | xargs $OPENER)"
      --bind "$NIX_SHELL_KEY:become($NIX_SHELL_CMD)"
      --bind "$PRINT_PREVIEW_KEY:execute($CMD preview \$(cat $STATE_FILE) {} | less)"
    )

    declare -a INDEXES=(
      "nixpkgs ctrl-n"
      "home-manager ctrl-h"
      "all ctrl-a"
    )

    for elem in "''${INDEXES[@]}"; do
      index=$(echo "$elem" | awk '{ print $1 }')
      keybind=$(echo "$elem" | awk '{ print $2 }')

      prompt=""
      indexes_flag=""
      if [[ -n "$index" && "$index" != "all" ]]; then
        indexes_flag="--indexes $index"
        prompt="$index"
      fi

      bind="$keybind:change-prompt($prompt> )+change-preview($CMD preview $indexes_flag {})+reload($CMD print $indexes_flag)+execute(echo $indexes_flag > $STATE_FILE)"

      fzf_args+=(--bind "$bind")
      HEADER="$HEADER$keybind - $index"$'\n'
    done

    fzf_args+=(
      --layout reverse
      --scheme history

      --header "$HEADER"
      --header-first
      --header-border
      --header-label "Help"
    )

    "$CMD" print | fzf "''${fzf_args[@]}"
''
