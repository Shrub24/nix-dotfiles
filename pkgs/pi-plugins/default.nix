# Source recipes for the extensions Pi-Bolt can compile in. Which ones a build contains is the module's decision.
{
  lib,
  fetchurl,
  fetchFromGitHub,
  linkFarm,
  writeShellApplication,
  python3,
  nix,
  piExtensions,
  piPowerlineFooter,
  pi-otel,
  piBoltPlugins,
  piBolt,
}:
let
  # One updater owns this set; nix-update cannot locate individual helper calls.
  # The npm name is kept beside the tarball: the lock's members are named to the
  # updater by it, so nothing has to read it back out of this file.
  npmTarball =
    name:
    {
      version,
      hash,
    }:
    {
      inherit name version;
      src = fetchurl {
        url = "https://registry.npmjs.org/${name}/-/${lib.last (lib.splitString "/" name)}-${version}.tgz";
        inherit hash;
      };
    };
  # The local plugins come from the same pinned checkout as the runtime ones.
  checkout = name: "${piExtensions}/${name}";
  # No releases: pinned to a deploy/edge commit that carries @omniroute/pi-agent.
  omnirouteSrc = fetchFromGitHub {
    owner = "Shrub24";
    repo = "OmniRoute";
    rev = "438930705452d2ce43d4e90fa1da91c1ac2e97d6";
    fetchSubmodules = false;
    sha256 = "sha256-4AYwqWmBuNGojnx0eiD7uTgvfSklMQLgj9lixdKEqT8=";
  };
  # No releases: pinned to a default-branch commit; `/fork-in-herdr` is the entry compiled in.
  forkInSrc = fetchFromGitHub {
    owner = "onsails";
    repo = "fork-in";
    rev = "1f3465a4fe0993812fd460b6f1c60a34351c6058";
    fetchSubmodules = false;
    sha256 = "sha256-SAD0HKq1onzCexOGKgy3J+6/0tdmI9/IpQFxQtSz31M=";
  };
  recipes = {
    plugins = {
      tool-repair = {
        tarball = npmTarball "pi-tool-repair" {
          version = "0.3.9";
          hash = "sha512-DhNdHn2rNixXk1fxVBwrbri1G1a+TNNWpoLY3V41aU0LJZfztCWmVare2rYFk/wmNdQ+rsrPd3NLBKJ86AS4EA==";
        };
        entry = "tool-repair.ts";
      };
      recap = {
        tarball = npmTarball "@zhcsyncer/pi-recap" {
          version = "0.4.3";
          hash = "sha512-W3svqRw42ip4mHPt/NESGjS4zwAHmdxlcBj2EBnTxB8qWfTIGeMQnd8+sT+aRXMVPNZAxCArRuN96MQnQLo+Fw==";
        };
        entry = "extensions/recap.ts";
      };
      rewind = {
        tarball = npmTarball "pi-rewind-hook" {
          version = "1.8.7";
          hash = "sha512-5d+X5waUwtfOS9xqQpAnFt34lUSwPGhoekA4C/XisUhZDWYdQ11g8BO4OwCRTFZppmoai37ce/xy9MO7M82kbA==";
        };
        entry = "index.ts";
      };
      cache-optimizer = {
        tarball = npmTarball "pi-cache-optimizer" {
          version = "2.10.4";
          hash = "sha512-Y0e7RzN7ehK0xN5atreN/jHyCdBNhFI0IwtWGgPn9j7aMPe8xK+tMjmkb8lqlktyRcfzLD6wH8Z4o1CR47w3og==";
        };
        entry = "index.ts";
      };
      context-view = {
        tarball = npmTarball "pi-context-view" {
          version = "0.7.2";
          hash = "sha512-i8jtZJA1ovhMLsBHHWE0mB8mzX28Mhm125Zy4QDiD9+bYCgcsYdMzXE7fPnmtx64MB3MNkMIAeMtTrJQ7HtuWQ==";
        };
        entry = "src/index.ts";
      };
      powerline-footer = {
        dir = piPowerlineFooter;
        entry = "index.ts";
      };
      anthropic-auth = {
        tarball = npmTarball "@gotgenes/pi-anthropic-auth" {
          version = "3.4.3";
          hash = "sha512-w2WwBxUKY4pLOHYvVdkR39lDrFgRrETIs3Oh5iCK461nL5MhKjW18iBjBD9DkTJlcavKZkrRvRvQnLz9o8DVMg==";
        };
        entry = "src/index.ts";
        # Pi-Bolt's own preamble must be shaped too; detection misses it otherwise.
        patch = ''
          substituteInPlace plugins/anthropic-auth/src/constants.ts \
            --replace-fail \
              '  "You are an expert coding assistant operating inside pi, a coding agent harness.";' \
              '  "You are an expert coding assistant operating inside pi, a coding agent harness.";

          export const PI_BOLT_DEFAULT_PROMPT_PREFIX =
            "You are an expert coding assistant operating inside Pi-Bolt, a build of pi (a coding agent harness) compiled ahead of time.";

          export const PI_DEFAULT_PROMPT_PREFIXES = [
            PI_DEFAULT_PROMPT_PREFIX,
            PI_BOLT_DEFAULT_PROMPT_PREFIX,
          ] as const;'

          substituteInPlace plugins/anthropic-auth/src/system-prompt-shaping.ts \
            --replace-fail \
              '  PI_DEFAULT_PROMPT_PREFIX,' \
              '  PI_DEFAULT_PROMPT_PREFIXES,' \
            --replace-fail \
              'text.startsWith(PI_DEFAULT_PROMPT_PREFIX)' \
              'PI_DEFAULT_PROMPT_PREFIXES.some((prefix) => text.startsWith(prefix))' \
            --replace-fail \
              '!block.text.includes(PI_DEFAULT_PROMPT_PREFIX)' \
              '!PI_DEFAULT_PROMPT_PREFIXES.some((prefix) => block.text.includes(prefix))'
        '';
      };
      tool = {
        tarball = npmTarball "@narumitw/pi-tool" {
          version = "0.3.3";
          hash = "sha512-+baoJZ8C2B9SR4jkV6K7CNCRkr8up5gSmm1tUfYZ8Z3vDwj+E05Olsh0G2dv8ud1pRxsPrJ+dT9qFUOxNatQRg==";
        };
        entry = "dist/index.ts";
      };
      loop-police = {
        tarball = npmTarball "pi-loop-police" {
          version = "1.14.1";
          hash = "sha512-gEp4SIAtU7UpSpe1Bs2OxA8B7rYejdunXNFpDdqo6hyLklS5b4SOQgBiyKCd3P1Xk/zHqqDCbWCcgUB4YDMyrw==";
        };
        entry = "extensions/loop-police.ts";
        # Mutable config lives beside the agent directory, not in the compiled source tree.
        patch = ''
          substituteInPlace plugins/loop-police/extensions/loop-police.ts \
            --replace-fail 'import { dirname, isAbsolute, join, resolve } from "node:path";' 'import { isAbsolute, join, resolve } from "node:path";' \
            --replace-fail 'import { fileURLToPath } from "node:url";' "" \
            --replace-fail 'import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";' 'import { getAgentDir, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";' \
            --replace-fail 'const EXT_DIR = dirname(fileURLToPath(import.meta.url));' "" \
            --replace-fail 'const CONFIG_PATH = join(EXT_DIR, "loop-police.json");' 'const CONFIG_PATH = join(getAgentDir(), "loop-police.json");'
        '';
      };
      ask-user-question = {
        tarball = npmTarball "@juicesharp/rpiv-ask-user-question" {
          version = "2.13.9";
          hash = "sha512-vx9CIkRHbzavPr7DFYUjorfaYErAVwurZOs2tKC5kQFv5y05CShlxf3qQ7k67lqvODdz8j/sbMIaj6szgLyCEg==";
        };
        entry = "index.ts";
        # Locale files are source-relative; keep the built-in English fallback.
        patch = ''
          substituteInPlace plugins/ask-user-question/index.ts \
            --replace-fail '@juicesharp/rpiv-i18n/loader' './i18n-loader.ts'
          printf '%s\n' 'export function registerLocalesFromDir() {}' > plugins/ask-user-question/i18n-loader.ts
        '';
      };
      todo = {
        tarball = npmTarball "@juicesharp/rpiv-todo" {
          version = "2.13.9";
          hash = "sha512-fXuUVU2HlxiUMeDeRTXbSVDPftP+CMGe47nAA5H0BX4YYl7chl1M2fSL1fFQqq5FCcpk5+ZBiQ43tiKvUu97gQ==";
        };
        entry = "index.ts";
        # The English fallback replaces the optional i18n peer.
        # A snapshot missing a task subject crashes the renderer on resume, so replay validates task entries.
        patch = ''
          substituteInPlace plugins/todo/index.ts \
            --replace-fail '@juicesharp/rpiv-i18n/loader' './i18n-loader.ts'
          printf '%s\n' 'export function registerLocalesFromDir() {}' > plugins/todo/i18n-loader.ts
          substituteInPlace plugins/todo/state/i18n-bridge.ts \
            --replace-fail '@juicesharp/rpiv-i18n' './i18n-scope.ts'
          printf '%s\n' 'export function scope() { return (_key: string, fallback: string) => fallback; }' > plugins/todo/state/i18n-scope.ts
          substituteInPlace plugins/todo/state/replay.ts \
            --replace-fail 'return Array.isArray(v.tasks) && typeof v.nextId === "number";' \
            'return Array.isArray(v.tasks) && typeof v.nextId === "number" && v.tasks.every((task) => !!task && typeof task === "object" && typeof (task as { subject?: unknown }).subject === "string");'
        '';
      };
      permission-system = {
        tarball = npmTarball "@gotgenes/pi-permission-system" {
          version = "41.0.0";
          hash = "sha512-BJHnj4yrtVMT5A5Tzss+yRhdvRndJSEBMr4j3QGa+T5MxmHof1xTKlVlDA6Xiq3hFQ7LcvTTCxzvXfPW85zftA==";
        };
        entry = "src/index.ts";
        # Embed the parser's wasm instead of resolving it next to the source, and
        # skip the `npm root -g` subprocess: there is no global node_modules here.
        patch = ''
          substituteInPlace plugins/permission-system/src/access-intent/bash/parser.ts \
            --replace-fail 'import { createRequire } from "node:module";' 'import treeSitterWasmFile from "web-tree-sitter/web-tree-sitter.wasm" with { type: "file" };
          import bashWasmFile from "tree-sitter-bash/tree-sitter-bash.wasm" with { type: "file" };' \
            --replace-fail '  const req = createRequire(import.meta.url);' "" \
            --replace-fail 'req.resolve("web-tree-sitter/web-tree-sitter.wasm")' 'treeSitterWasmFile' \
            --replace-fail 'req.resolve("tree-sitter-bash/tree-sitter-bash.wasm")' 'bashWasmFile'
          substituteInPlace plugins/permission-system/src/path/node-modules-discovery.ts \
            --replace-fail 'return discoverGlobalNodeModulesViaSubprocess();' 'return null;'
        '';
      };
      vcc = {
        tarball = npmTarball "@sting8k/pi-vcc" {
          version = "0.10.2";
          hash = "sha512-7vTuOaIRZGRnChb+ZWysYtYKsZgF3KFfiJpufBl03q5KZouKAgGUdiAdfTCOM71mTSEL/gUi2+TBsmy1Y0KxYA==";
        };
        entry = "index.ts";
      };
      herdsman = {
        dir = checkout "pi-herdsman";
        # The lock member's manifest, relative to the pi-extensions input. Written
        # as a path so the updater can combine manifests without a store path
        # evaluated before the pins moved.
        manifest = "pi-herdsman/package.json";
        entry = "extension/index.ts";
        # Its sibling imports are relative into the staged plugins directory, so
        # bash-processes has to be staged beside it.
        dependencies = [ "bash-processes" ];
        # Children on stock Pi still need the extension path; bundled definitions
        # must remain readable from disk rather than Bun's virtual filesystem.
        patch = ''
          substituteInPlace plugins/herdsman/extension/index.ts \
            --replace-fail 'const HERDSMAN_EXTENSION_PATH = fileURLToPath(import.meta.url);' 'const HERDSMAN_EXTENSION_PATH = "${checkout "pi-herdsman"}/extension/index.ts";' \
            --replace-fail '"../../pi-bash-processes/extensions/background-work.ts"' '"../../bash-processes/extensions/background-work.ts"'
          substituteInPlace plugins/herdsman/extension/advisory-wake.ts \
            --replace-fail '"../../pi-bash-processes/extensions/wake-consumer.ts"' '"../../bash-processes/extensions/wake-consumer.ts"'
          substituteInPlace plugins/herdsman/extension/agent-definitions.ts \
            --replace-fail 'const BUILTIN_AGENT_DIR = fileURLToPath(
            new URL("./agent-definitions", import.meta.url),
          );' 'const BUILTIN_AGENT_DIR = "${checkout "pi-herdsman"}/extension/agent-definitions";'
        '';
      };
      tool-renderer = {
        dir = checkout "pi-tool-renderer";
        entry = "extensions/tool-renderer.ts";
        # bash-processes imports it by package name, so the builder links it into
        # that plugin's node_modules instead of it being staged as a sibling.
        packageName = "pi-tool-renderer";
      };
      output-policy = {
        dir = checkout "pi-output-policy";
        entry = "extensions/output-policy.ts";
      };
      bash-processes = {
        dir = checkout "pi-bash-processes";
        entry = "extensions/background-tasks.ts";
        dependencies = [ "tool-renderer" ];
      };
      jev = {
        dir = checkout "pi-jev";
        entry = "extensions/compiled.ts";
        # Its entry imports permission-system by a path relative to the staged
        # siblings, so that plugin is staged even where this one is not selected.
        dependencies = [ "permission-system" ];
        # Keep both portable entries; the compiled manifest needs one factory.
        patch = ''
          chmod u+w plugins/jev/extensions
          cat > plugins/jev/extensions/compiled.ts <<'EOF'
          import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
          import permissions from "./permission-authorizer.ts";
          import intent from "./tool-intent.ts";
          export default function jev(pi: ExtensionAPI) { permissions(pi); intent(pi); }
          EOF
          substituteInPlace plugins/jev/extensions/gotgenes.ts \
            --replace-fail 'return import(specifier);' 'return import("../../permission-system/src/service.ts");'
        '';
      };
      reqcap = {
        dir = checkout "pi-reqcap";
        entry = "extensions/index.ts";
      };
      cbmem = {
        dir = checkout "pi-cbmem";
        entry = "extensions/cbmem.ts";
      };
      omniroute = {
        dir = "${omnirouteSrc}/@omniroute/pi-agent";
        entry = "src/index.ts";
      };
      # Its default entry sniffs the host from argv[0], which a binary named
      # pi-bolt cannot answer; src/pi.ts registers the Pi commands outright.
      fork-in = {
        dir = forkInSrc;
        entry = "src/pi.ts";
      };
      # Reuse the runtime package's lock-derived dependency closure.
      otel = {
        dir = "${pi-otel}";
        manifest = "pi-otel/package.json";
        entry = "src/index.ts";
        # AOT has no source-relative package.json; keep the stock version.
        patch = ''
          substituteInPlace plugins/otel/src/version.ts \
            --replace-fail 'import { readFileSync } from "node:fs";' "" \
            --replace-fail 'const url = new URL("../package.json", import.meta.url);
              const pkg = JSON.parse(readFileSync(url, "utf8")) as { version?: string };
              cached = typeof pkg.version === "string" && pkg.version.length > 0 ? pkg.version : "0.0.0";' \
            'cached = "${pi-otel.version}";'
        '';
      };
    };
  };

  # `pluginName` must stay the row id: the launchers pass `-e builtin:<id>`.
  toPlugin =
    id: recipe:
    piBoltPlugins.buildPiBoltPlugin {
      pname = id;
      # A plugin built from an input checkout takes the manifest's version, so a
      # pi-extensions bump moves it with the input. Tarball recipes keep "0":
      # their version is the pin's, which names the source already.
      version =
        if recipe ? manifest then (lib.importJSON "${piExtensions}/${recipe.manifest}").version else "0";
      pluginName = id;
      packageName = recipe.packageName or null;
      src = if recipe ? tarball then recipe.tarball.src else recipe.dir;
      inherit (recipe) entry;
      dependencies = builtins.map pluginOf (recipe.dependencies or [ ]);
      postPatch = lib.optionalString (recipe ? patch) (
        lib.replaceStrings [ "plugins/${id}/" ] [ "" ] recipe.patch
      );
    };

  pluginOf = id: plugins.${id};
  plugins = lib.mapAttrs toPlugin recipes.plugins;

  sources = linkFarm "pi-plugins" (
    lib.mapAttrsToList (id: path: {
      name = "plugins/${id}";
      inherit path;
    }) plugins
  );

  # Plugins with npm dependencies need a workspace in the lock. bash-processes is absent:
  # its one dependency is a `workspace:*` sibling the builder links from the recipe's edge.
  lockMembers = [
    "ask-user-question"
    "herdsman"
    "otel"
    "permission-system"
    "todo"
    "tool"
  ];
  # Where each member's manifest comes from, as the updater reads it: a tarball
  # pin names its package, and a checkout declares the manifest relative to the
  # pi-extensions input. Read as a path rather than a store path so the lock can
  # be regenerated in the run that moves the pins.
  lockMemberSources = lib.concatStringsSep " " (
    map (
      id:
      let
        recipe = recipes.plugins.${id};
      in
      if recipe ? manifest then
        "${id}=manifest:${recipe.manifest}"
      else
        "${id}=npm:${recipe.tarball.name}"
    ) lockMembers
  );
in
sources.overrideAttrs (_: {
  version = "unstable";
  meta.position = "${__curPos.file}:${toString __curPos.line}";
  passthru = {
    updateScript = lib.getExe (writeShellApplication {
      name = "pi-plugins-update";
      runtimeInputs = [
        python3
        nix
        # The lock's generator: the updater combines the refreshed manifests in
        # the same run, so pins and lock never disagree in the working copy.
        piBolt.updatePluginLock
      ];
      # The input the directory-shaped members live in, and the member list: both
      # are read by the updater so the recipe file is not parsed for them.
      text = ''
        export PI_EXTENSIONS_ROOT=${piExtensions}
        export PI_LOCK_MEMBERS="${lockMemberSources}"
        exec python3 ${./update.py}
      '';
    });
    # The lock regenerated from the pins already in the tree: the tool to run
    # after a pi-extensions bump, which moves member manifests without moving an
    # npm pin. It is the updater's own lock step, not a second implementation.
    updateLock = writeShellApplication {
      name = "pi-plugins-update-lock";
      runtimeInputs = [
        python3
        nix
        piBolt.updatePluginLock
      ];
      text = ''
        export PI_EXTENSIONS_ROOT=${piExtensions}
        export PI_LOCK_MEMBERS="${lockMemberSources}"
        exec python3 ${./update.py} --lock-only
      '';
    };
    inherit plugins;
  };
})
