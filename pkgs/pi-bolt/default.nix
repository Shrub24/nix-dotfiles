{
  lib,
  stdenv,
  fetchurl,
  writeText,
  buildNpmPackage,
  # Source, version and the runtime the AOT step compiles with all come from
  # pkgs/_sources (nvfetcher.toml): one release tag carries the tree and the
  # runtime archive together.
  src,
  version,
  runtime,
  # The plugin recipes (pkgs/pi-plugins) and the caller's selection of them;
  # which plugins a build contains is not this expression's business.
  piPlugins,
  plugins ? { },
  pname ? "pi-bolt",
  rsync,
  python3,
  patchelf,
  makeBinaryWrapper,
  fd,
  ripgrep,
  wl-clipboard,
}:
let
  # bash-processes imports tool-renderer's intent helper, so the renderer's
  # source is staged whenever the former is built, registered or not.
  staged =
    plugins
    // lib.optionalAttrs (plugins ? bash-processes) { inherit (piPlugins.plugins) tool-renderer; }
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
in
buildNpmPackage {
  inherit pname version src;

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-8oNz19f9Eg9O5Jxvs8+06S9rfJRCoZ1+HKk+AOjwahw=";
  # Skip the canvas test dependency's native build; runtime WASM is staged below.
  npmRebuildFlags = [ "--ignore-scripts" ];
  npmBuildScript = "build:offline";
  nativeBuildInputs = [
    rsync
    python3
    patchelf
    makeBinaryWrapper
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
    # with; only its binary is taken. nvfetcher yields the tarball, not a tree.
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
    export BUN_JSC_maximumAOTCandidateBytecodeSize=357039
    PIBOLT_BUILD_LOG=$TMPDIR/aot.log scripts/build-pi.sh --plugins "$PWD/plugins/plugins.ts" \
      --cpu baseline --jit on --out out/pi-bolt || { tail -40 $TMPDIR/aot.log; exit 1; }
  '';
  installPhase = ''
    runHook preInstall
    # Assets and native helpers resolve relative to the executable.
    mkdir -p $out/lib $out/bin
    cp -r out/pi-bolt $out/lib/pi-bolt
    # Pi runs `rg` and `fd` for its grep and find tools and `wl-copy`/`wl-paste` for
    # the clipboard, looking each up in PATH first and only then downloading it. The
    # wrapper makes them findable; being a binary wrapper it costs one exec and does
    # not disturb process.execPath, so assets still resolve.
    makeBinaryWrapper $out/lib/pi-bolt/pi $out/bin/pi-bolt \
      --prefix PATH : ${
        lib.makeBinPath [
          fd
          ripgrep
          wl-clipboard
        ]
      }
    runHook postInstall
  '';

  dontStrip = true;
  dontPatchELF = true;
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    version=$(BUN_STATIC_HEAP_VERBOSE=1 $out/bin/pi-bolt --version 2>&1)
    printf '%s\n' "$version"
    grep -q 'image registered: true' <<< "$version"
    # The wrapper is what puts rg, fd and wl-copy on Pi's PATH.
    for dir in ${fd}/bin ${ripgrep}/bin ${wl-clipboard}/bin; do
      grep -a -q "$dir" $out/bin/pi-bolt
    done
    runHook postInstallCheck
  '';
}
