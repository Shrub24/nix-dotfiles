# Source recipes for the extensions Pi-Bolt can compile in: where each plugin's
# source comes from, which file exports its factory, which sibling plugins it
# imports, and the patch its compile-time assumptions need (`--replace-fail`
# keeps a patch loud when upstream moves). Which plugins a build contains is the
# module's decision, so nothing here says who gets what.
{
  lib,
  fetchurl,
  fetchFromGitHub,
  linkFarm,
  runCommand,
  writeText,
  writeShellApplication,
  python3,
  nix,
  piExtensions,
  # The footer fork's repository, an input like pi-extensions: the whole tree is
  # the plugin directory its recipe stages.
  piPowerlineFooter,
  pi-otel,
  # Pi-Bolt's plugin scope: the builder each recipe becomes, and the fetcher the
  # libraries use. An input rather than a vendored copy, so the interface this
  # repository tests is the one Pi-Bolt publishes.
  piBoltPlugins,
}:
let
  # One updater owns this set; nix-update cannot locate individual helper calls.
  npmTarball =
    name:
    {
      version,
      hash,
    }:
    fetchurl {
      url = "https://registry.npmjs.org/${name}/-/${lib.last (lib.splitString "/" name)}-${version}.tgz";
      inherit hash;
    };
  # The local plugins come from the same pinned checkout as the runtime ones.
  checkout = name: "${piExtensions}/${name}";
  # OmniRoute publishes no releases, so the pin tracks the deploy/edge branch's
  # commit — the line that carries @omniroute/pi-agent.
  omnirouteSrc = fetchFromGitHub {
    owner = "Shrub24";
    repo = "OmniRoute";
    rev = "438930705452d2ce43d4e90fa1da91c1ac2e97d6";
    fetchSubmodules = false;
    sha256 = "sha256-4AYwqWmBuNGojnx0eiD7uTgvfSklMQLgj9lixdKEqT8=";
  };
  # fork-in publishes no releases either, so its pin tracks the default branch's
  # commit — the fork entrypoint `/fork-in-herdr` is what we compile in.
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
          version = "2.10.0";
          hash = "sha512-3ODSj705TZem6ZjvXnuyqa7y/Mu7t8OQfL7L8ix378stHHQUcMia4JdF7coIXmT+KSXSJomZ+ylBSHx7y/ZxfA==";
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
      # Footer and Vim editor backend in one plugin.
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
          version = "0.3.2";
          hash = "sha512-6pRKKRmYF7otun14utUtbxOEkWEPz/GfENyJj15pGblNKWUh8S74v8WO2w+3WecldY+QDG/i1BWlK1MmlvDIRg==";
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
        # The locale files are source-relative; keep its built-in English fallback
        # rather than resolving store assets.
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
        # The i18n SDK is an optional peer and its locale files are
        # source-relative, so both imports become the inline English fallback.
        # A persisted snapshot that lost a task's subject otherwise reaches the
        # renderer's string sanitizer and dies on `.replace` at resume, so the
        # replay boundary validates task entries instead.
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
        packageName = "@vanillagreen/pi-tool-renderer";
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

    # Runtime dependencies the compiled plugins import, resolved from the plugin
    # tree's own node_modules.
    libraries = {
      # Resolved from the plugin tree's own node_modules.
      # (dir name) = tarball
      # 0.5.1 is the floor the plugin sources need: `pi-radar/communication`
      # arrived in 0.3.0, and 0.5.1 is the release that requires daemon wire
      # revision 4, so presence is not silently unserved.
      "pi-radar" = npmTarball "pi-radar" {
        version = "0.5.1";
        hash = "sha512-VZKxHqehBtIV80ZizTKXeBTQx+q6w2djmFdvvhrNqHQ02N58qc2D6abbTr5QYM6BxfiDVku4TKqnChuwC3yGyA==";
      };
      "@narumitw/pi-tui-kit" = npmTarball "@narumitw/pi-tui-kit" {
        version = "0.65.6";
        hash = "sha512-uy+JGV/GamhLGamN932ZXEuBwfqsp6j+A7H0Qzjzn8ha+NDAEmKXk2nlmVpvnxeqEsu9zX0B0wQ2p9C8+XOZiQ==";
      };
      "grok-mermaid" = npmTarball "grok-mermaid" {
        version = "0.2.3";
        hash = "sha512-/4KopAbsjvuRP9MdPtlDjOHUmUVEohOX73JNcsWpzAtFxh+bq5+Dhb6gzvRieLDwIPQIR3/vy8V1NNTuz4Zsmg==";
      };
      "highlight.js" = npmTarball "highlight.js" {
        version = "11.12.0";
        hash = "sha512-nbfWpyRMcMrPMmDwJB+dhX/eiaPKtc2RB+0QZskqJ3WjRA/FDS0e9hZrx8EC/lbEv8gXy98FcDbNa/dspAaJMg==";
      };
      "yaml" = npmTarball "yaml" {
        version = "2.9.1";
        hash = "sha512-3NxN8+78OdzbT7C/WjGsyfPAtJaN3FNDsWxv7Y7mcDsT/oOmgW8BpyQQFFBnvZE3j9Y2Sdz1ULFLezL7Eb2yFw==";
      };
      "@juicesharp/rpiv-config" = npmTarball "@juicesharp/rpiv-config" {
        version = "2.13.9";
        hash = "sha512-wCy7w4PNi+9pVD5gsbsIxq6ysdoFKXGPIQfOICyITW/+Jg6OGlFZa/tG99J9OZvTHDM8ZwUvqXNrFRsU6Z8NTQ==";
      };
      "zod" = npmTarball "zod" {
        version = "4.6.7";
        hash = "sha512-g8W2D2kU6a8untc053fX1uVBKzM7yqAxW/3zwk83+6RyF2+SKOuV+c0wBDhUwzV1PaGapmZH+rmcUzPf+3CGwg==";
      };
      "web-tree-sitter" = npmTarball "web-tree-sitter" {
        version = "0.27.1";
        hash = "sha512-qtx0VyUyNRHtL3ze7+v0hCKB/sLcAmY7ZAVp/ZK/bCj0yED8ptvNrr7Vd7DwDyKDWN9baqcUx4uaD2r2ql+6IA==";
      };
      "tree-sitter-bash" = npmTarball "tree-sitter-bash" {
        version = "0.25.1";
        hash = "sha512-7hMytuYIMoXOq24yRulgIxthE9YmggZIOHCyPTTuJcu6EU54tYD+4G39cUb28kxC6jMf/AbPfWGLQtgPTdh3xw==";
      };
      "typebox" = npmTarball "typebox" {
        version = "1.4.2";
        hash = "sha512-eSoZzgSIyOKDtTH9MI7XMAxMaiXq7UiSFWarysN1ka66baTLDxAVdQ6WkWn6qDqsJFVrcjzvuP+CqHo9yrlQpg==";
      };
    };
  };
  # The npm packages the compiled plugins import, unpacked once: Pi-Bolt's
  # builder copies this into each plugin's own node_modules, so a plugin resolves
  # its dependencies inside the payload's tree.
  libraryPackages = writeText "pi-plugins-libraries.json" (
    builtins.toJSON (
      lib.mapAttrsToList (name: path: {
        inherit name;
        path = toString path;
      }) recipes.libraries
    )
  );
  libraryNodeModules = runCommand "pi-plugins-node-modules" { } ''
    ${python3}/bin/python3 ${./unpack-libraries.py} ${libraryPackages}
  '';

  # A recipe becomes the flake's plugin derivation: the same source pin and entry,
  # with the patch's `plugins/<id>/` prefix dropped because the builder works in
  # the plugin's own tree. `pluginName` is the row id, so the launchers' existing
  # `-e builtin:<id>` arguments keep naming these plugins.
  toPlugin =
    id: recipe:
    piBoltPlugins.buildPiBoltPlugin {
      pname = id;
      # The pins of record are the recipe's own; a plugin's version is not
      # separately meaningful, and the source hash still separates two of them.
      version = "0";
      pluginName = id;
      packageName = recipe.packageName or null;
      src = recipe.tarball or recipe.dir;
      inherit (recipe) entry;
      dependencies = builtins.map pluginOf (recipe.dependencies or [ ]);
      nodeModules = "${libraryNodeModules}/node_modules";
      postPatch = lib.optionalString (recipe ? patch) (
        lib.replaceStrings [ "plugins/${id}/" ] [ "" ] recipe.patch
      );
    };

  # A recipe names its plugin dependencies by row id; the builder wants the
  # derivations, and the plugin map below is where they live.
  pluginOf = id: plugins.${id};
  plugins = lib.mapAttrs toPlugin recipes.plugins;

  sources = linkFarm "pi-plugins" (
    lib.mapAttrsToList (id: path: {
      name = "plugins/${id}";
      inherit path;
    }) plugins
    ++ lib.mapAttrsToList (name: path: {
      name = "libraries/${name}";
      inherit path;
    }) recipes.libraries
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
      ];
      text = ''
        exec python3 ${./update.py}
      '';
    });
    inherit plugins;
  };
})
