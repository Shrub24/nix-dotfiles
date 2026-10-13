# One row per extension, consumed twice: `source` is what Pi's discovery reads
# from settings.json, `path` is the installed location a discovery-off launch
# passes as -e, and `id` names the recipe in pkgs/pi-plugins. `compiled` names
# the launchers that enable it. The one Pi-Bolt executable compiles every row
# naming `lead`; a launcher enables its compiled rows through `-e builtin:<id>`,
# and a compiled row is filtered from the lead's runtime -e list. A source or path may carry one
# placeholder: `@home@`, `@extensions@` (the pinned pi-extensions input),
# `@package@<name>[/subpath]` (an installed extension package), or `@recipe@<id>`
# (the source a pkgs/pi-plugins recipe resolves).
[
  {
    id = "otel";
    compiled = [
      "lead"
      "child"
    ];
    source = "@package@pi-otel";
    path = "@package@pi-otel";
  }
  {
    id = "web-access";
    source = "npm:pi-web-access";
    path = "@home@/.pi/agent/npm/node_modules/pi-web-access";
  }
  # Routes `route/<role>` virtual models over native physical candidates. Lead and
  # child both load it so delegated workers resolve the same routes.
  {
    id = "native-router";
    source = "@extensions@/pi-native-router";
    path = "@extensions@/pi-native-router";
  }
  {
    id = "magic-context";
    source = "@package@pi-magic-context";
    path = "@package@pi-magic-context";
  }
  # pi-recap writes its own config (temp file + rename), so its model and
  # multiplexer template stay a one-time `/recap-config` pass.
  {
    id = "recap";
    compiled = [ "lead" ];
    source = "npm:@zhcsyncer/pi-recap";
  }
  {
    id = "rewind";
    compiled = [ "lead" ];
    source = "npm:pi-rewind-hook";
  }
  {
    id = "i-have-adhd";
    source = "git:github.com/ayghri/i-have-adhd";
    path = "@home@/.pi/agent/git/github.com/ayghri/i-have-adhd";
    overrides = {
      skills = [ ];
    };
  }
  {
    id = "tool";
    compiled = [
      "lead"
      "child"
    ];
    source = "npm:@narumitw/pi-tool";
  }
  {
    id = "context-view";
    compiled = [ "lead" ];
    source = "npm:pi-context-view";
  }
  # The footer's status line and Vim editor backend, which replace the dropped
  # vim and starship rows.
  {
    id = "powerline-footer";
    compiled = [
      "lead"
      "child"
    ];
    source = "@recipe@powerline-footer";
  }
  {
    id = "omniroute";
    compiled = [
      "lead"
      "child"
    ];
    source = "@recipe@omniroute";
  }
  {
    id = "commandcode-provider";
    source = "npm:pi-commandcode-provider";
    path = "@home@/.pi/agent/npm/node_modules/pi-commandcode-provider";
  }
  # OpenSec's Bun build of pi-fff: same engine, config file and flags, without
  # needing the JIT for the native path. The two builds are alternatives — the
  # official installer offers this one only where @ff-labs/pi-fff is absent.
  {
    id = "fff";
    source = "npm:opensec-pi-fff";
    path = "@home@/.pi/agent/npm/node_modules/opensec-pi-fff";
  }
  # The model's task list as a live panel, on the `todo` tool. Bun only.
  {
    id = "todo";
    source = "npm:opensec-pi-todo";
    path = "@home@/.pi/agent/npm/node_modules/opensec-pi-todo";
  }
  {
    id = "herdsman";
    compiled = [
      "lead"
      "child"
    ];
    source = "@extensions@/pi-herdsman";
    path = "@extensions@/pi-herdsman";
  }
  {
    id = "cbmem";
    compiled = [
      "lead"
      "child"
    ];
    source = "@extensions@/pi-cbmem";
  }
  {
    id = "ask-user-question";
    compiled = [ "lead" ];
    source = "npm:@juicesharp/rpiv-ask-user-question";
  }
  {
    id = "cache-optimizer";
    compiled = [
      "lead"
      "child"
    ];
    source = "npm:pi-cache-optimizer";
  }
  {
    id = "bash-processes";
    compiled = [
      "lead"
      "child"
    ];
    source = "@extensions@/pi-bash-processes";
  }
  {
    id = "tool-renderer";
    compiled = [ "lead" ];
    source = "@extensions@/pi-tool-renderer";
  }
  {
    id = "extension-manager";
    source = "npm:@vanillagreen/pi-extension-manager";
    path = "@home@/.pi/agent/npm/node_modules/@vanillagreen/pi-extension-manager";
  }
  {
    id = "output-policy";
    compiled = [
      "lead"
      "child"
    ];
    source = "@extensions@/pi-output-policy";
  }
  {
    id = "reqcap";
    compiled = [
      "lead"
      "child"
    ];
    source = "@extensions@/pi-reqcap";
  }
  {
    id = "permission-system";
    compiled = [
      "lead"
      "child"
    ];
    source = "npm:@gotgenes/pi-permission-system";
  }
  {
    id = "loop-police";
    compiled = [
      "lead"
      "child"
    ];
    source = "npm:pi-loop-police";
  }
  # Package dir, not entry files — a file path fails with "package source not
  # found". Its two entry files come from the package manifest.
  {
    id = "jev";
    compiled = [
      "lead"
      "child"
    ];
    source = "@extensions@/pi-jev";
    path = "@extensions@/pi-jev";
  }
  {
    id = "tool-repair";
    compiled = [
      "lead"
      "child"
    ];
    source = "npm:pi-tool-repair";
  }
  {
    id = "fork-in";
    compiled = [
      "lead"
    ];
    source = "@recipe@fork-in";
  }
  {
    id = "anthropic-auth";
    compiled = [
      "lead"
      "child"
    ];
    source = "npm:@gotgenes/pi-anthropic-auth";
  }
]
