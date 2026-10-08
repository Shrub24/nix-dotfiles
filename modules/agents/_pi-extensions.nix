# One row per extension, consumed twice: `source` is what Pi's discovery reads
# from settings.json, `path` is the installed location a discovery-off launch
# passes as -e, and `id` names the recipe in pkgs/pi-plugins. `compiled` names
# the builds that bake it in — a compiled factory loads unconditionally, so such
# a row is filtered from that build's -e list. A source or path may carry one
# placeholder: `@home@`, `@extensions@` (the pinned pi-extensions input) or
# `@recipe@<id>` (the source a pkgs/pi-plugins recipe resolves).
[
  {
    id = "web-access";
    source = "npm:pi-web-access";
    path = "@home@/.pi/agent/npm/node_modules/pi-web-access";
  }
  # The only row that reads a live checkout instead of an installed copy: the
  # fork at ~/Projects/dev/custom/magic-context is what the lead loads, so it is
  # developed here. Replace with a @recipe@ source once the fork has a recipe,
  # which is what every other row does.
  {
    id = "magic-context";
    source = "npm:@cortexkit/pi-magic-context";
    path = "@home@/Projects/dev/custom/magic-context/packages/pi-plugin";
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
  {
    id = "vim";
    compiled = [ "lead" ];
    source = "npm:pi-vim";
  }
  {
    id = "starship";
    compiled = [ "lead" ];
    source = "npm:@narumitw/pi-starship";
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
    id = "fff";
    source = "npm:@ff-labs/pi-fff";
    path = "@home@/.pi/agent/npm/node_modules/@ff-labs/pi-fff";
  }
  {
    id = "draft-history";
    compiled = [ "lead" ];
    source = "npm:pi-draft-history";
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
    compiled = [ "lead" ];
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
    compiled = [ "lead" ];
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
    id = "intercom";
    source = "npm:pi-intercom";
    path = "@home@/.pi/agent/npm/node_modules/pi-intercom";
  }
  {
    id = "loop-police";
    compiled = [ "lead" ];
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
  # pi-vcc is the children's compaction path; it has no settings entry.
  {
    id = "vcc";
    compiled = [ "child" ];
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
    compiled = [ "lead" ];
    source = "npm:@gotgenes/pi-anthropic-auth";
  }
]
