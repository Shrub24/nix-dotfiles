{
  coreutils,
  herdr,
  jq,
  writeShellApplication,
}:
writeShellApplication {
  name = "herdr-nvim-zoom";

  runtimeInputs = [
    coreutils
    herdr
    jq
  ];

  text = ''
    # Keybind scripts run without HERDR_PANE_ID, so --current is unavailable:
    # both panes are resolved from `herdr pane list`, the sidebar by its title.
    focused=$(herdr pane list | jq -r '
      .result.panes
      | map(select(.focused))[0]
      | [.pane_id, .workspace_id, .cwd]
      | @tsv')
    [ -n "$focused" ] || exit 0
    pane_id=$(echo "$focused" | cut -f1)
    workspace=$(echo "$focused" | cut -f2)
    cwd=$(echo "$focused" | cut -f3)
    pid=$(herdr pane list | jq -r --arg ws "$workspace" '
      .result.panes
      | map(select(.workspace_id == $ws
                   and .terminal_title_stripped == "nvim sidebar"))[0].pane_id
      // empty')
    if [ -n "$pid" ]; then
      herdr pane close "$pid"
    else
      herdr plugin pane open --plugin chmarax.herdr-nvim --entrypoint sidebar \
        --placement zoomed --target-pane "$pane_id" --cwd "$cwd"
    fi
  '';
}
