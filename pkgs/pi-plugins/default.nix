# Source recipes for the extensions Pi-Bolt can compile in. Which ones a build contains is the module's decision.
{
  lib,
  fetchurl,
  fetchFromGitHub,
  linkFarm,
  writeShellApplication,
  writeText,
  python3,
  nix,
  piExtensions,
  piExtensionPlugins,
  piExtensionLockCandidates,
  piPowerlineFooter,
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
      # An npm archive unpacks under package/, which holds its package.json.
      manifest = "package/package.json";
      src = fetchurl {
        url = "https://registry.npmjs.org/${name}/-/${lib.last (lib.splitString "/" name)}-${version}.tgz";
        inherit hash;
      };
    };
  # The local plugins come from the same pinned checkout as the runtime ones.
  checkout = name: "${piExtensions}/${name}";
  # The producer's plugin lock candidates, in this file's recipe shape.
  upstreamCandidates = lib.mapAttrs (
    _: candidate:
    if candidate ? npm then
      {
        tarball = npmTarball candidate.npm.name {
          inherit (candidate.npm) version hash;
        };
      }
    else
      { inherit (candidate) manifest; }
  ) piExtensionLockCandidates;
  # A checkout recipe's manifest is its package.json at the checkout's path, relative to the
  # pi-extensions root, which the lock reads as a path. Attributes may name another.
  fromCheckout =
    name: attrs:
    {
      dir = checkout name;
      manifest = "${name}/package.json";
    }
    // attrs;
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
          version = "0.3.10";
          hash = "sha512-3lN74Sxvf0ywav0c+DYoWXeuN0m+bZqPO0olHmhwSApiIZQy0gIynWtLypGC71yIfjYxtcMRs0Rk/WPlSNQsrA==";
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
          version = "1.8.8";
          hash = "sha512-vicXPos9+qcEZsFGrS6amTLQYZWSdw5clCRIbUm5IOVLG1U2wf7uVuurT8tgmQAi4fnk3faztB9VYcS6SqlMgg==";
        };
        entry = "index.ts";
      };
      cache-optimizer = {
        tarball = npmTarball "pi-cache-optimizer" {
          version = "2.10.5";
          hash = "sha512-vSaKlCnRMNkAq6q1dY6s9UEy+A6PSRKTCGokm9bUC+/M0MOnP8le3OcbJ3UYgJym1e6GnZfH7f+/caeCsL/dbA==";
        };
        entry = "index.ts";
      };
      context-view = {
        tarball = npmTarball "pi-context-view" {
          version = "0.8.3";
          hash = "sha512-gkeblBXXwz0uxhCSWa4RrMU64E3TYHr8vSyM10wcIkOAKaL8zoO6ob4bE9s+KjFfNVZ7WcPClSDnOOo2BjyhUw==";
        };
        entry = "src/index.ts";
      };
      powerline-footer = {
        dir = piPowerlineFooter;
        entry = "index.ts";
      };
      anthropic-auth = {
        tarball = npmTarball "@gotgenes/pi-anthropic-auth" {
          version = "3.4.4";
          hash = "sha512-oWCkPFSa7AkvSju3OrlYu0GTo8Jdqz2OvszJtHj0hzXLw8tErtmPPMYPqK2it3zaXu+Wl2oH8nfpeIUVsqW2Vw==";
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
          version = "0.4.2";
          hash = "sha512-ap4mSHkhLQ6v/CYE9SIuZ+fWJiCKHCe9tYlDkgsWq17cMuksXIuBFD3ion8bUg00lq5wJo9gJN3DEXrVoKBfUw==";
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
          version = "2.15.0";
          hash = "sha512-Gm6de5IZF52BaSeh9dnDqJBn821Z5XfJkCmhkCmqTzvNv3SCpSv1mA4Gj5VBcfrSe+xTtWSVQzJwIqJFQHH3Lg==";
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
          version = "2.15.0";
          hash = "sha512-8WfYssdgQgSWzFNsRzdw5Z6ZJIjO2ecM/YqEzYpR/ore+Hh5aNmafGVy94uFbIofAv2wGGitx5e3J/ucRrViXQ==";
        };
        entry = "index.ts";
        # The English fallback replaces the optional i18n peer. The hygiene hooks prune
        # completed tasks at the turn boundary and surface the ones still open; the
        # replacements carry the store file's tab indentation, hence printf.
        patch = ''
          install -m644 ${./patches/todo-hygiene.ts} plugins/todo/state/hygiene.ts
          startHook="$(printf '%b' 'pi.on("before_agent_start", async (_event, ctx) => {\n\t\tconst message = openTasksMessage(ctx);\n\t\treturn message ? { message } : undefined;\n\t});\n\n\tpi.on("agent_start", async (_event, ctx) => {')"
          flushHook="$(printf '%b' 'todoOverlay?.hideCompletedTasksFromPreviousTurn();\n\t\tif (flushCompleted(pi, ctx)) void updateTodoOverlay();')"
          importHook="$(printf '%b' 'import { replayFromBranch } from "./state/replay.ts";\nimport { flushCompleted, openTasksMessage } from "./state/hygiene.ts";')"
          substituteInPlace plugins/todo/index.ts \
            --replace-fail 'import { replayFromBranch } from "./state/replay.ts";' "$importHook" \
            --replace-fail 'pi.on("agent_start", async () => {' "$startHook" \
            --replace-fail 'todoOverlay?.hideCompletedTasksFromPreviousTurn();' "$flushHook" \
            --replace-fail '@juicesharp/rpiv-i18n/loader' './i18n-loader.ts'
          printf '%s\n' 'export function registerLocalesFromDir() {}' > plugins/todo/i18n-loader.ts
          substituteInPlace plugins/todo/state/i18n-bridge.ts \
            --replace-fail '@juicesharp/rpiv-i18n' './i18n-scope.ts'
          printf '%s\n' 'export function scope() { return (_key: string, fallback: string) => fallback; }' > plugins/todo/state/i18n-scope.ts
        '';
      };
      permission-system = {
        tarball = npmTarball "@gotgenes/pi-permission-system" {
          version = "42.0.0";
          hash = "sha512-imhOymTbnj1iqnJDujqtnp79Su63PyQ+SAP0UqooC2E9yL9HzP/ISYTYkthvhq2aNbwTPBZZSjqI3jBdvmZ7ZQ==";
        };
        entry = "src/index.ts";
        # jev imports it by name; the link needs this.
        packageName = "@gotgenes/pi-permission-system";
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
      # Radar's registrar: herdsman imports it by name, and its baseline is the entry its children load from disk.
      jev = fromCheckout "pi-jev" {
        entry = "extensions/compiled.ts";
        # Its entry imports the permission system by name.
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
          # A compiled build cannot resolve a deferred specifier.
          substituteInPlace plugins/jev/extensions/gotgenes.ts \
            --replace-fail 'return import(specifier);' 'return import("@gotgenes/pi-permission-system");'
        '';
      };
      neuralwatt = {
        tarball = npmTarball "@aliou/pi-neuralwatt" {
          version = "0.19.1";
          hash = "sha512-YpBLw3GC2xRxOvVns9KlLw8F6AAHkcZGEJmaJ0l6juB84STMH6x1LMGbWOcKOiyRzh4eWXa8nKZScz7UwbLYjg==";
        };
        entry = "extensions/compiled.ts";
        # The package ships three entries - provider, quota command, quota warnings -
        # and a compiled plugin carries one, so this one loads all three.
        patch = ''
          cat > plugins/neuralwatt/extensions/compiled.ts <<'EOF'
          import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
          import commandQuotas from "./command-quotas/index.ts";
          import provider from "./provider/index.ts";
          import quotaWarnings from "./quota-warnings/index.ts";

          export default async function neuralwatt(pi: ExtensionAPI) {
            await provider(pi);
            await commandQuotas(pi);
            await quotaWarnings(pi);
          }
          EOF
        '';
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
        lib.replaceStrings [ "plugins/${id}/" ] [ "" ] (
          if lib.isFunction recipe.patch then recipe.patch { radar = pluginOf "radar"; } else recipe.patch
        )
      );
    };

  # The plugins pi-extensions builds itself, taken from its published packages by
  # name rather than re-declared here: a plugin's build identity is its producer's.
  upstreamOwned = [
    "bash-processes"
    "cbmem"
    "copy-mode"
    "herdsman"
    "otel"
    "output-policy"
    "radar"
    "reqcap"
    "tool-renderer"
  ];
  upstreamPlugins = lib.getAttrs upstreamOwned piExtensionPlugins;

  pluginOf = id: plugins.${id};
  plugins = upstreamPlugins // lib.mapAttrs toPlugin recipes.plugins;

  sources = linkFarm "pi-plugins" (
    lib.mapAttrsToList (id: path: {
      name = "plugins/${id}";
      inherit path;
    }) plugins
  );

  # Every plugin with a manifest or an npm tarball is a lock candidate; the updater keeps the
  # ones whose manifest declares dependencies. A candidate names its manifest relative to its
  # source: the pi-extensions root for a checkout, the archive for an npm tarball.
  lockCandidates = writeText "pi-plugin-lock-candidates.json" (
    builtins.toJSON (
      lib.mapAttrsToList
        (
          id: recipe:
          if recipe ? tarball then
            {
              inherit id;
              npm = recipe.tarball.name;
              manifest = recipe.tarball.manifest;
              tarball = "${recipe.tarball.src}";
            }
          else
            {
              inherit id;
              inherit (recipe) manifest;
            }
        )
        (
          lib.filterAttrs (_: recipe: recipe ? manifest || recipe ? tarball) (
            recipes.plugins // upstreamCandidates
          )
        )
    )
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
      # The input the checkout manifests live in, and the candidate list: both are read by
      # the updater so the recipe file is not parsed for them.
      text = ''
        export PI_EXTENSIONS_ROOT=${piExtensions}
        export PI_LOCK_CANDIDATES=${lockCandidates}
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
        export PI_LOCK_CANDIDATES=${lockCandidates}
        exec python3 ${./update.py} --lock-only
      '';
    };
    inherit plugins;
  };
})
