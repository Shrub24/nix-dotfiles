# Source recipes for the extensions Pi-Bolt can compile in: where each plugin's
# source comes from, which file exports its factory, and the patch its
# compile-time assumptions need (`--replace-fail` keeps a patch loud when
# upstream moves). Which plugins a build contains is the module's decision, so
# nothing here says who gets what.
{
  lib,
  fetchurl,
  fetchFromGitHub,
  linkFarm,
  writeShellApplication,
  python3,
  nix,
  piExtensions,
  # The footer fork's repository, an input like pi-extensions: the whole tree is
  # the plugin directory its recipe stages.
  piPowerlineFooter,
  pi-otel,
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
          version = "0.3.7";
          hash = "sha512-1tnZ/TgAQqLf3eGU8cf1AV9Tug1WcR2GcKrtV7wRq2xgNfh1RCy0/DS2QZB1Z1azrvBuffO3Utu5FTfOeSaorw==";
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
          version = "2.8.25";
          hash = "sha512-X1IGrpESoVJ+xYwI11OGtwLuuzEv/rtodFRPxZKST+ACaYdLSamPHg0ENinKP1ntuHJsyp4rRKfRs1qy9eKl+g==";
        };
        entry = "index.ts";
      };
      context-view = {
        tarball = npmTarball "pi-context-view" {
          version = "0.7.1";
          hash = "sha512-74bg+Tb5SOVdjeUSW70I/yieDtAKcNeEETPj5zU3UFWlYnE3NCjGgA/fLCi6vsO9vmwbRcFmCINJBaoksxH1aw==";
        };
        entry = "src/index.ts";
      };
      # The footer and the Vim editor backend in one plugin, which is what
      # retires the separate vim, starship and draft-history extensions.
      powerline-footer = {
        dir = piPowerlineFooter;
        entry = "index.ts";
      };
      anthropic-auth = {
        tarball = npmTarball "@gotgenes/pi-anthropic-auth" {
          version = "3.4.2";
          hash = "sha512-xNbI8eYKZmfk2PRqNoogULF69mjKeCnX/ZQJo50mkG6ibu+asYNTZaBWYpAW1RQVyprPfFoBBgNhha+jxRluZg==";
        };
        entry = "src/index.ts";
        # Pi-Bolt replaces Pi's default preamble with its own, which detection
        # here never matched: the verbose preamble then reached Anthropic OAuth
        # unshaped. Accept either preamble.
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
        # Its mutable config belongs beside the agent directory, not in the source
        # tree it no longer has once compiled.
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
          version = "2.13.8";
          hash = "sha512-Uu2jpn5Tf0lo47izmPU7+xbUIuxE9HdmmZ6XjVzBSm8zIvnJ5Hoj/XhfuG0qC0DuCOwIkE0oNRsNsLp1js7/2g==";
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
      permission-system = {
        tarball = npmTarball "@gotgenes/pi-permission-system" {
          version = "40.2.1";
          hash = "sha512-PXmYiJpdoOknpmPEDEkjPecRlSc081MYPLlB7aRg7E0G8ixekJhdO50/xmBtI0AjJLD2qFrhS2FIB3VHRHX3dA==";
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
      };
      output-policy = {
        dir = checkout "pi-output-policy";
        entry = "extensions/output-policy.ts";
      };
      bash-processes = {
        dir = checkout "pi-bash-processes";
        entry = "extensions/background-tasks.ts";
        # It imports tool-renderer's intent helper, which a compiled build resolves
        # against the staged sibling source rather than a package specifier.
        patch = ''
          substituteInPlace \
            plugins/bash-processes/extensions/background-tasks.ts \
            plugins/bash-processes/extensions/registrations.ts \
            --replace-fail '"@vanillagreen/pi-tool-renderer/intent"' '"../../tool-renderer/extensions/tool-renderer/intent.ts"'
          substituteInPlace plugins/bash-processes/extensions/background-tasks.ts \
            --replace-fail '"@vanillagreen/pi-tool-renderer/managed-bash"' '"../../tool-renderer/extensions/tool-renderer/managed-bash.ts"'
        '';
      };
      jev = {
        dir = checkout "pi-jev";
        entry = "extensions/compiled.ts";
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
      "pi-radar" = npmTarball "pi-radar" {
        version = "0.1.0";
        hash = "sha512-9baj9YvynilcmDNDs16B1qtioqvpQ2VY6EhOydwUwUwkhebyBhD/ERmQk9Q8go2vyZvIANWtL7GMOh1nq4TAoA==";
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
        version = "2.13.8";
        hash = "sha512-fNzUmtGHRYbPQ3PWnfwyk0ukBxUgIwFLUhzRQV8U47IMhSZAEfoutqOZ31UCPPEpCgWgF+WATJ3+jn7NwJUotg==";
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
        version = "1.3.37";
        hash = "sha512-k+Qogwk7lztlItGvFf5v4GZPPStFAFehAyOKYeuqIHzi3dfTFqPOTx38JG09hmpcK6TQgctrTD06U/0CTTpM1g==";
      };
    };
  };
  sources = linkFarm "pi-plugins" (
    lib.mapAttrsToList (id: plugin: {
      name = "plugins/${id}";
      path = plugin.tarball or plugin.dir;
    }) recipes.plugins
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
    plugins = lib.mapAttrs (
      id: plugin:
      plugin
      // (
        if plugin ? tarball then
          {
            tarball = "${sources}/plugins/${id}";
          }
        else
          {
            dir = "${sources}/plugins/${id}";
          }
      )
    ) recipes.plugins;
    libraries = lib.mapAttrs (name: _: "${sources}/libraries/${name}") recipes.libraries;
  };
})
