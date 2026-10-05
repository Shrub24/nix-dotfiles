# Source recipes for the extensions Pi-Bolt can compile in: where each plugin's
# source comes from, which file exports its factory, and the patch its
# compile-time assumptions need (`--replace-fail` keeps a patch loud when
# upstream moves). Which plugins a build contains is the module's decision, so
# nothing here says who gets what.
{
  lib,
  fetchgit,
  fetchurl,
  fetchFromGitHub,
  dockerTools,
  piExtensions,
}:
let
  # nvfetcher cannot source npm registry tarballs, so these pins stay hand-written.
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
  generatedSources = import ../_sources/generated.nix {
    inherit
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };
in
{
  plugins = {
    tool-repair = {
      tarball = npmTarball "pi-tool-repair" {
        version = "0.3.5";
        hash = "sha512-PoVCqRKqYG93oi28AimiYvhNCAiz3/ooCSezvi/2ykbaJ95PcTKq7k5xv/9znqtGqx17FCj2Vbs9Aq/w7m2xyQ==";
      };
      entry = "tool-repair.ts";
    };
    draft-history = {
      tarball = npmTarball "pi-draft-history" {
        version = "0.1.2";
        hash = "sha512-JQim9ijOxbCYqIiCE+smSLg+4LVtxP4xtHtUnzhaQ9k+5gtD8gImkH0n1oXzgM0BBBecc8lWrk2rd8OKtMMMsw==";
      };
      entry = "src/index.ts";
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
        version = "2.8.19";
        hash = "sha512-nJPXytQzpWD6BnXm877RhWi3sL7m8tkQxBrUUE+xknK9VjNvVq9SYmAEInsLD1UawaEIRe8QWgZBhMYa7n9UBA==";
      };
      entry = "index.ts";
    };
    context-view = {
      tarball = npmTarball "pi-context-view" {
        version = "0.6.0";
        hash = "sha512-Ngo1m+3lzyi4AE1WxYW2MRKOAYdzvL3XcZSmJg27fqAlJPuDM3Rnp+rqheFBe3ElX+wsK4xZuv1CaZb+FrFKRA==";
      };
      entry = "src/index.ts";
    };
    vim = {
      tarball = npmTarball "pi-vim" {
        version = "0.14.2";
        hash = "sha512-CFSKJvOCNToueIMyBgsujT+gHa4sAlLOnT4VYZ6iCGKJ7M24eCVWFKKnnMt6tmP1rDE6T7k/AqBrb6LWzCzRaQ==";
      };
      entry = "index.ts";
    };
    anthropic-auth = {
      tarball = npmTarball "@gotgenes/pi-anthropic-auth" {
        version = "3.4.2";
        hash = "sha512-xNbI8eYKZmfk2PRqNoogULF69mjKeCnX/ZQJo50mkG6ibu+asYNTZaBWYpAW1RQVyprPfFoBBgNhha+jxRluZg==";
      };
      entry = "src/index.ts";
    };
    tool = {
      tarball = npmTarball "@narumitw/pi-tool" {
        version = "0.3.2";
        hash = "sha512-6pRKKRmYF7otun14utUtbxOEkWEPz/GfENyJj15pGblNKWUh8S74v8WO2w+3WecldY+QDG/i1BWlK1MmlvDIRg==";
      };
      entry = "dist/index.ts";
    };
    starship = {
      tarball = npmTarball "@narumitw/pi-starship" {
        version = "0.58.0";
        hash = "sha512-bj4nLFq3GA0xJ80xHd0WNsV+a4jHnthOz5egcadPhEYG2iRNq/e9EyBehxwFtOL95grqz6y120oJiDIS26bsqw==";
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
        version = "2.12.0";
        hash = "sha512-DilWc7u25SwnK6ytuAWOTerP0AmOEfK4HXpgS1oEzkgv9d5g5T+PbLG+zcLn18M3B/J3poMG14iydG5O6iBsnw==";
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
        version = "40.0.0";
        hash = "sha512-9oPZCWUoZuwiWVZtytyqFwZ4+qix0u5rma8og2CLtiHOgR6W/eDWEjqWv+8YXh4dx1uKorq+kUtWIMgsWlaTUQ==";
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
        version = "0.9.0";
        hash = "sha512-OL93+fJ1lcdGd5avh/YXBsBA53fHTmHguW3wb47Ykhb0G2adzmcRY8C/j+TkmIS8ASZijNhyCuYyQmH4GItDcg==";
      };
      entry = "index.ts";
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
      dir = "${generatedSources.omniroute.src}/@omniroute/pi-agent";
      entry = "src/index.ts";
    };
  };

  # Runtime dependencies of pi-tool and pi-starship, resolved from the plugin
  # tree's own node_modules.
  libraries = {
    # Resolved from the plugin tree's own node_modules.
    # (dir name) = tarball
    "@narumitw/pi-tui-kit" = npmTarball "@narumitw/pi-tui-kit" {
      version = "0.60.0";
      hash = "sha512-2QGXp9Od4HzkytCh74K+N9C5BNIhRDifx3gEGQldDjjgRrR4W7SWU3H6e6gxAc5JOUtF2uv1pePRL5buJGrydA==";
    };
    "grok-mermaid" = npmTarball "grok-mermaid" {
      version = "0.2.3";
      hash = "sha512-/4KopAbsjvuRP9MdPtlDjOHUmUVEohOX73JNcsWpzAtFxh+bq5+Dhb6gzvRieLDwIPQIR3/vy8V1NNTuz4Zsmg==";
    };
    "highlight.js" = npmTarball "highlight.js" {
      version = "11.12.0";
      hash = "sha512-nbfWpyRMcMrPMmDwJB+dhX/eiaPKtc2RB+0QZskqJ3WjRA/FDS0e9hZrx8EC/lbEv8gXy98FcDbNa/dspAaJMg==";
    };
    "smol-toml" = npmTarball "smol-toml" {
      version = "1.8.0";
      hash = "sha512-kCZr2V3ch9i00x8zXRhjUNVcjG9ijES5dDudkXvUVCT5QlJNQWElSJdZqyPemffHoLNUYwOcou0Fy+ojN0uHSQ==";
    };
    "yaml" = npmTarball "yaml" {
      version = "2.9.1";
      hash = "sha512-3NxN8+78OdzbT7C/WjGsyfPAtJaN3FNDsWxv7Y7mcDsT/oOmgW8BpyQQFFBnvZE3j9Y2Sdz1ULFLezL7Eb2yFw==";
    };
    "@juicesharp/rpiv-config" = npmTarball "@juicesharp/rpiv-config" {
      version = "2.12.0";
      hash = "sha512-eGjoCDCKz2JtKIUIpZ2y8CAVjxZYXCKa2D64ByozhkAWVblXsgyFLrQMk5k5Bv5RXRrA3GY66XNG5ExtEuGASA==";
    };
    "zod" = npmTarball "zod" {
      version = "4.6.5";
      hash = "sha512-v5l/aFXZQeai4awLbOpSoHecE9UiMrnfx75tEXLjNonXVARxQ5mOeipTjROUchszUNCqnE+hqAMujRsRHsut2Q==";
    };
    "web-tree-sitter" = npmTarball "web-tree-sitter" {
      version = "0.26.13";
      hash = "sha512-5bUZ7vbQ1kcondet96wzP974+JfCZDeQ7bTpacICm2nnvHpa5cO0ByRsoMcAhUP+743vpkb4m0BFlVSm+Ye9VA==";
    };
    "tree-sitter-bash" = npmTarball "tree-sitter-bash" {
      version = "0.25.1";
      hash = "sha512-7hMytuYIMoXOq24yRulgIxthE9YmggZIOHCyPTTuJcu6EU54tYD+4G39cUb28kxC6jMf/AbPfWGLQtgPTdh3xw==";
    };
    "typebox" = npmTarball "typebox" {
      version = "1.3.27";
      hash = "sha512-zu+jc1pcy4UiNThxikUr36f0Rybk9PEeCg/NE6adeWr/SKsdNO4EzZHYRDlv2YCVAfj3Odq3dESSo/jNyoBXzA==";
    };
  };
}
