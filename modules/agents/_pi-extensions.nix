# One row per extension. `source` feeds stock Pi and Pi-Bolt package lists;
# `path` is for a runtime extension passed directly to managed children. `id`
# names the compiled recipe and `compiled` names its roles.
#
# `@extensions@/<dir>` is the checkout: stock Pi can load it, but it has no
# `node_modules` and Pi installs nothing for a local path, so a plugin that
# declares npm dependencies cannot resolve them from there. Those rows name the
# built plugin (`@recipe@`) instead, whose tree the builder stages the closure
# into.
[
  {
    id = "otel";
    compiled = [
      "lead"
      "child"
    ];
    source = "@recipe@otel";
  }
  {
    id = "web-access";
    source = "npm:pi-web-access";
    path = "@home@/.pi/agent/npm/node_modules/pi-web-access/dist/index.js";
  }
  # Routes `route/<role>` virtual models over native physical candidates. Lead and
  # child both load it so delegated workers resolve the same routes.
  {
    id = "native-router";
    source = "@extensions@/pi-native-router";
    path = "@extensions@/pi-native-router/src/index.ts";
  }
  {
    id = "magic-context";
    source = "@package@pi-magic-context";
    path = "@package@pi-magic-context/dist/index.js";
  }
  {
    id = "memtrace";
    source = "@extensions@/pi-memtrace";
  }
  # Configured once with `/recap-config`: it rewrites its own config by rename.
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
  }
  {
    id = "neuralwatt";
    compiled = [
      "lead"
      "child"
    ];
    source = "@recipe@neuralwatt";
  }
  # Runtime-loaded: its shared proxy daemon runs from the package's own sources,
  # which a compiled payload cannot carry.
  {
    id = "freeflow";
    source = "@package@pi-freeflow";
  }
  # Alternative to @ff-labs/pi-fff; the official installer offers this one only where that is absent.
  {
    id = "fff";
    source = "npm:opensec-pi-fff";
  }
  # Compiled so its replay guard travels with it (see the recipe's patch).
  {
    id = "todo";
    compiled = [
      "lead"
      "child"
    ];
    source = "npm:@juicesharp/rpiv-todo";
  }
  # Herdsman's shared Radar registrar: compiled in, with no runtime package of its own.
  {
    id = "radar";
    compiled = [
      "lead"
      "child"
    ];
  }
  {
    id = "herdsman";
    compiled = [
      "lead"
      "child"
    ];
    source = "@recipe@herdsman";
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
    source = "@recipe@bash-processes";
  }
  {
    id = "tool-renderer";
    compiled = [ "lead" ];
    source = "@recipe@tool-renderer";
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
