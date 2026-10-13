{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  writeText,
  buildNpmPackage,
  writeShellApplication,
  nix-update,
  nix,
  # The plugin recipes (pkgs/pi-plugins) and the caller's selection of them;
  # which plugins a build contains is not this expression's business.
  piPlugins,
  plugins ? { },
  # The ids the child launcher enables, a subset of `plugins`. The payload
  # compiles all of `plugins`; each launcher only chooses what it enables.
  childPlugins ? [ ],
  # The extensions the lead entrypoint loads at runtime, as paths. The caller
  # owns the list because its entries carry the operator's home directory.
  extensions ? [ ],
  runtimeShell,
  rsync,
  python3,
  patchelf,
  makeBinaryWrapper,
  fd,
  ripgrep,
  wl-clipboard,
}:
assert lib.all (id: lib.hasAttr id plugins) childPlugins;
let
  # The upstream release pin. This package owns it: a tag is the only version
  # the tree and the runtime archive are published at together, upstream's
  # release workflow asserting the tree's VERSION equals the tag, so the
  # derivation's version is that tag minus upstream's prefix.
  tag = "bolt-v0.9.1";
  version = lib.removePrefix "bolt-v" tag;
  src = fetchFromGitHub {
    owner = "opensec-git";
    repo = "Pi-Bolt";
    rev = tag;
    fetchSubmodules = false;
    sha256 = "sha256-iSSKop4Scd+tSfvFJza2PKezniAIrgmnGZQytydao5g=";
  };
  # The archive beside the tag is the Bun build the AOT step compiles with, so
  # the tag keys its URL.
  runtime = fetchurl {
    url = "https://github.com/opensec-git/Pi-Bolt/releases/download/${tag}/pi-bolt-runtime-linux-x64.tar.gz";
    sha256 = "sha256-mtQw5iD4wL7A/Q8EstKi4yMbPignT3xcHIApV87Dlhc=";
  };

  executable = "pi-bolt";
  # The lead also publishes the primary name, so nothing outside this package
  # has to route `pi`. A symlink keeps one script for both names.
  extraBins = [ "pi" ];

  # bash-processes imports tool-renderer's intent helper, so the renderer's
  # source is staged whenever the former is built, registered or not.
  staged =
    plugins
    // lib.optionalAttrs (plugins ? bash-processes) { inherit (piPlugins.plugins) tool-renderer; }
    // lib.optionalAttrs (plugins ? herdsman) {
      inherit (piPlugins.plugins) bash-processes tool-renderer;
    }
    // lib.optionalAttrs (plugins ? jev) { inherit (piPlugins.plugins) permission-system; };

  unpack = dir: tarball: ''
    mkdir -p ${dir}
    tar -xzf ${tarball} --strip-components=1 -C ${dir}
  '';
  stage =
    id: plugin:
    if plugin ? tarball then
      unpack "plugins/${id}" plugin.tarball
    else
      ''
        mkdir -p plugins/${id}
        cp -r ${plugin.dir}/. plugins/${id}/
      '';
  pluginDirs = lib.concatStringsSep "\n" (
    map (id: stage id staged.${id}) (lib.attrNames staged)
    ++ lib.mapAttrsToList (
      name: tarball: unpack "plugins/node_modules/${name}" tarball
    ) piPlugins.libraries
  );
  pluginPatches = lib.concatStringsSep "\n" (
    map (id: staged.${id}.patch) (lib.filter (id: staged.${id} ? patch) (lib.attrNames staged))
  );

  manifest = writeText "plugins.ts" ''
    import type { InlineExtension } from "@earendil-works/pi-coding-agent";
    ${lib.concatStrings (
      lib.mapAttrsToList (id: p: ''
        import ${lib.replaceStrings [ "-" ] [ "_" ] id} from "./${id}/${p.entry}";
      '') plugins
    )}
    const plugins: InlineExtension[] = [
    ${
      lib.concatStrings (
        lib.mapAttrsToList (id: _: ''
          { name: "${id}", factory: ${lib.replaceStrings [ "-" ] [ "_" ] id} },
        '') plugins
      )
    }];

    export default plugins;
  '';

  catalogPin = lib.importJSON (src + "/nix/model-catalog.json");
  catalog = fetchurl {
    name = "pi-model-catalog.json";
    url = "https://pi.dev/api/models/revisions/${catalogPin.revision}?types=chat,image,classifier";
    sha256 = lib.removePrefix "sha256-" catalogPin.revision;
  };

  # Compilation, and nothing a launcher chooses. A launcher-only change —
  # another runtime -e path, a different filter — leaves this derivation alone,
  # so its AOT build is reused instead of repeated.
  payload = buildNpmPackage {
    # Carries the package's own name: the npm dependency derivation is named
    # after it, and a name of its own would re-fetch the same dependencies.
    pname = executable;
    inherit src version;

    npmDepsFetcherVersion = 2;
    npmDepsHash = "sha256-gtBnoE+/SXU1P7FKwwZ/qZOujJJhedFNvFslDXyDN9w=";
    # Skip the canvas test dependency's native build; runtime WASM is staged below.
    npmRebuildFlags = [ "--ignore-scripts" ];
    npmBuildScript = "build:offline";
    nativeBuildInputs = [
      rsync
      python3
      patchelf
    ];

    postPatch = ''
      patchShebangs scripts
    '';
    preBuild = ''
      node packages/ai/scripts/hydrate-model-catalog.ts ${catalog}
    '';
    postBuild = ''
      export HOME="$TMPDIR"
      # The archive beside the release tag is the Bun build the AOT step compiles
      # with; only its binary is taken.
      ${unpack ".work/runtime" runtime}
      # Set the loader before compiling: rewriting the final ELF damages its AOT payload.
      patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} .work/runtime/bun

      ${pluginDirs}
      ${pluginPatches}
      cp ${manifest} plugins/plugins.ts
      # Pi's tsconfig maps the host packages to packages/*/src while the executable is
      # bundled from packages/*/dist, so a compiled plugin would bind a second copy of
      # the host's classes and its patches would land on a class the app never renders
      # with. This tsconfig sits nearer the plugin files, so they resolve to the dist
      # modules the app itself uses (context/pi-bolt-compiled-plugins.md).
      cat > plugins/tsconfig.json <<'EOF'
      {
        "compilerOptions": {
          "paths": {
            "@earendil-works/pi-coding-agent": ["../../dist/index.js"],
            "@earendil-works/pi-coding-agent/*": ["../../dist/*"],
            "@earendil-works/pi-tui": ["../../../tui/src/index.ts"],
            "@earendil-works/pi-tui/*": ["../../../tui/src/*"],
            "@earendil-works/pi-ai": ["../../../ai/src/index.ts"],
            "@earendil-works/pi-ai/*": ["../../../ai/src/*.ts", "../../../ai/src/providers/*.ts"],
            "@earendil-works/pi-agent-core": ["../../../agent/src/index.ts"],
            "@earendil-works/pi-telemetry": ["../../../telemetry/src/index.ts"],
            "@earendil-works/pi-mcp": ["../../../mcp/src/index.ts"],
            "@earendil-works/pi-mcp/*": ["../../../mcp/src/*"],
            "@earendil-works/pi-codemode": ["../../../codemode/src/index.ts"],
            "@earendil-works/pi-codemode/*": ["../../../codemode/src/*"],
            "typebox": ["../../../../node_modules/typebox"]
          }
        }
      }
      EOF
      chmod -R u+w plugins
      # The largest single module's top-level bytecode, reported by the AOT step;
      # re-measure when the plugin set or the pinned tree changes.
      export BUN_JSC_maximumAOTCandidateBytecodeSize=500000
      PIBOLT_BUILD_LOG=$TMPDIR/aot.log scripts/build-pi.sh --plugins "$PWD/plugins/plugins.ts" \
        --cpu baseline --jit on --out out/pi-bolt || { tail -40 $TMPDIR/aot.log; exit 1; }
    '';
    installPhase = ''
      runHook preInstall
      # Assets and native helpers resolve relative to the executable.
      mkdir -p $out/lib
      cp -r out/pi-bolt $out/lib/pi-bolt
      runHook postInstall
    '';

    dontStrip = true;
    dontPatchELF = true;
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      version=$(BUN_STATIC_HEAP_VERBOSE=1 $out/lib/pi-bolt/pi --version 2>&1)
      printf '%s\n' "$version"
      grep -q 'image registered: true' <<< "$version"
      runHook postInstallCheck
    '';
  };

  # Named compiled plugins are builtins upstream; --no-extensions suppresses
  # them along with discovery, so each launcher opts its selected set back in.
  builtinArgs = lib.concatMap (id: [
    "-e"
    "builtin:${id}"
  ]);
  compiledArgs = builtinArgs (lib.attrNames plugins);
  childFlags = lib.concatMapStringsSep " " lib.escapeShellArg (builtinArgs childPlugins);

  # The lead opts in to Pi's builtins, compiled plugins and runtime extensions.
  leadArgs = lib.concatMapStringsSep " " (arg: lib.escapeShellArg arg) (
    [
      "--no-extensions"
      "-e"
      "builtin:mcp"
      "-e"
      "builtin:codemode"
      "-e"
      "builtin:tool-search"
      "-e"
      "builtin:llama.cpp"
    ]
    ++ compiledArgs
    ++ lib.concatMap (path: [
      "-e"
      path
    ]) extensions
  );

  # What the child launcher already enables. A definition still naming one of
  # them would register it a second time, which on the CLI is a startup failure.
  duplicateArms = lib.optionalString (childPlugins != [ ]) (
    (lib.concatMapStringsSep " | " (id: "*${id}*") childPlugins) + ") ;;"
  );

  # The script is written inside the output, so the root it names is the one it
  # is installed in: `placeholder` is the only way to say that before the build.
  leadEntrypoint = ''
    flags=(${leadArgs})
    # Herdr's reporter joins the launch as the shim, not as the path Herdr
    # installs it at: Pi-Bolt skips that file by name and header marker.
    # The shim exists once Herdr has written the file it links to; a
    # missing -e path is fatal.
    herdr="$HOME/.pi/agent/herdr-pi-state.ts"
    if [ -f "$herdr" ]; then flags+=(-e "$herdr"); fi
    # Herdsman reads this from its own environment and passes it into the
    # child pane; a session variable would reach every operator shell.
    export PI_HERDSMAN_CHILD_COMMAND=pi-bolt-child
    exec ${placeholder "out"}/lib/pi-bolt/bin/pi-bolt "''${flags[@]}" "$@"
  '';

  childEntrypoint = ''
    args=()
    # Herdsman supplies both when it leads the launch; a launch without them
    # would discover the settings packages the child compiles.
    has_no_extensions=
    for arg in "$@"; do
      case "$arg" in -ne | --no-extensions) has_no_extensions=1 ;; esac
    done
    while [ $# -gt 0 ]; do
      case "$1" in
      -e | --extension)
        if [ $# -lt 2 ]; then
          echo "pi-bolt-child: $1 needs a path" >&2
          exit 2
        fi
        case "''${2,,}" in
        ${duplicateArms}
        *) args+=("$1" "$2") ;;
        esac
        shift 2
        ;;
      *)
        args+=("$1")
        shift
        ;;
      esac
    done
    if [ -z "$has_no_extensions" ]; then
      args=(--no-extensions -e builtin:mcp -e builtin:codemode "''${args[@]}")
    fi
    exec ${placeholder "out"}/lib/pi-bolt/bin/pi-bolt ${childFlags} "''${args[@]}"
  '';
in
stdenv.mkDerivation {
  pname = executable;
  inherit version;
  meta.position = "${__curPos.file}:${toString __curPos.line}";

  passthru = {
    inherit payload;
    updateScript = lib.getExe (writeShellApplication {
      name = "pi-bolt-update";
      runtimeInputs = [
        python3
        nix-update
        nix
      ];
      text = ''
        exec python3 ${./update.py}
      '';
    });
    checkUpdate = writeShellApplication {
      name = "pi-bolt-check-update";
      runtimeInputs = [ python3 ];
      text = ''
        exec python3 ${./update.py} --latest
      '';
    };
  };

  nativeBuildInputs = [ makeBinaryWrapper ];
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    # Copied, not linked: herdr-radar's identity comparison needs the entrypoint
    # and the executable it runs in one store root, and the wrapper lands here.
    # The payload derivation stays shared, so an extensions-only change reuses
    # its AOT build.
    mkdir -p $out/lib $out/bin
    cp -r ${payload}/lib/pi-bolt $out/lib/pi-bolt
    chmod -R u+w $out/lib/pi-bolt
    # Pi runs `rg` and `fd` for its grep and find tools and `wl-copy`/`wl-paste` for
    # the clipboard, looking each up in PATH first and only then downloading it. The
    # wrapper makes them findable; being a binary wrapper it costs one exec and does
    # not disturb process.execPath, so assets still resolve.
    mkdir -p $out/lib/pi-bolt/bin
    makeBinaryWrapper $out/lib/pi-bolt/pi $out/lib/pi-bolt/bin/pi-bolt \
      --prefix PATH : ${
        lib.makeBinPath [
          fd
          ripgrep
          wl-clipboard
        ]
      }
    # A quoted heredoc: the shell keeps $HOME and the flag array for the launch,
    # and the root is interpolated by Nix, which is the only place that knows it.
    cat > $out/bin/${executable} <<'EOF'
    #!${runtimeShell}
    ${leadEntrypoint}
    EOF
    cat > $out/bin/pi-bolt-child <<'EOF'
    #!${runtimeShell}
    ${childEntrypoint}
    EOF
    chmod +x $out/bin/${executable} $out/bin/pi-bolt-child
    ${lib.concatMapStringsSep "\n" (name: "ln -s ${executable} $out/bin/${name}") extraBins}
    runHook postInstall
  '';

  # The copied payload is the AOT image the build produced: the same two skips
  # its own derivation needs, since stripping it damages the payload.
  dontStrip = true;
  dontPatchELF = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    # Every published name runs this output's payload, not another output's.
    for name in ${executable} pi-bolt-child ${lib.concatStringsSep " " extraBins}; do
      grep -q "$out/lib/pi-bolt/bin/pi-bolt" $out/bin/$name
    done
    version=$(BUN_STATIC_HEAP_VERBOSE=1 $out/bin/${executable} --version 2>&1)
    printf '%s\n' "$version"
    grep -q 'image registered: true' <<< "$version"
    # The wrapper is what puts rg, fd and wl-copy on Pi's PATH.
    for dir in ${fd}/bin ${ripgrep}/bin ${wl-clipboard}/bin; do
      grep -a -q "$dir" $out/lib/pi-bolt/bin/pi-bolt
    done
    ${lib.optionalString (plugins ? omniroute) ''
      ${python3}/bin/python3 ${./test_entrypoints.py} "$out/bin/${executable}" "$out/bin/pi-bolt-child"
    ''}
    runHook postInstallCheck
  '';
}
