{
  lib,
  stdenv,
  piBolt,
  plugins ? { },
  pluginLock ? null,
  childPlugins ? [ ],
  leadAgentDir ? null,
  childAgentDir ? null,
  orchestratorAgentDir ? null,
  herdsmanDataDir ? null,
  runtimeShell,
  python3,
  # The one program Pi looks for in PATH and would otherwise download.
  wl-clipboard,
}:
assert lib.all (id: lib.hasAttr id plugins) childPlugins;
let
  inherit (piBolt) version;

  # Compilation only: launcher changes leave this derivation, and its AOT build, alone.
  # `maxAotCandidateBytecodeSize` is re-measured when the plugin set changes.
  sharedEnv = lib.optionalAttrs (herdsmanDataDir != null) {
    PI_HERDSMAN_DATA_DIR = herdsmanDataDir;
    PI_HERDSMAN_CHILD_COMMAND = "pi-bolt-child";
  };
  launchers = {
    pi-bolt = {
      env =
        sharedEnv
        // lib.optionalAttrs (leadAgentDir != null) {
          PI_CODING_AGENT_DIR = leadAgentDir;
        };
      path = [ wl-clipboard ];
    };
  }
  // lib.optionalAttrs (orchestratorAgentDir != null) {
    pi-bolt-orchestrator = {
      env = sharedEnv // {
        PI_CODING_AGENT_DIR = orchestratorAgentDir;
      };
      path = [ wl-clipboard ];
    };
  };
  payload =
    (
      (piBolt.override {
        jit = true;
        maxAotCandidateBytecodeSize = 500000;
      }).withPlugins
        (_: builtins.attrValues plugins)
    ).override
      {
        inherit launchers;
        inherit pluginLock;
      };

  tools = payload.passthru.runtimeInputs ++ [ wl-clipboard ];
  executable = "pi-bolt";
  extraBins = [ "pi" ] ++ lib.optional (orchestratorAgentDir != null) "pi-bolt-orchestrator";
  builtinArgs = lib.concatMap (id: [
    "-e"
    "builtin:${id}"
  ]);
  childFlags = lib.concatMapStringsSep " " lib.escapeShellArg (
    builtinArgs (
      [
        "mcp"
        "codemode"
      ]
      ++ childPlugins
    )
  );
  childAgentDirEnv = lib.optionalString (childAgentDir != null) ''
    export PI_CODING_AGENT_DIR="''${PI_CODING_AGENT_DIR:-${lib.escapeShellArg childAgentDir}}"
  '';
  herdsmanDataDirEnv = lib.optionalString (herdsmanDataDir != null) ''
    export PI_HERDSMAN_DATA_DIR="''${PI_HERDSMAN_DATA_DIR:-${lib.escapeShellArg herdsmanDataDir}}"
  '';

  duplicateArms =
    lib.concatMapStringsSep " | " (id: "builtin:${id}") (
      [
        "mcp"
        "codemode"
      ]
      ++ childPlugins
    )
    + ") ;;";

  execPayload = "exec ${placeholder "out"}/lib/pi-bolt/pi";
  childEntrypoint = ''
    args=()
    # Restore the child's compiled subset only when Herdsman disables discovery.
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
    ${childAgentDirEnv}
    ${herdsmanDataDirEnv}
    export PATH=${lib.makeBinPath tools}:$PATH
    if [ -n "$has_no_extensions" ]; then
      ${execPayload} ${childFlags} "''${args[@]}"
    else
      ${execPayload} "''${args[@]}"
    fi
  '';
in
stdenv.mkDerivation {
  pname = executable;
  inherit version;
  meta.position = "${__curPos.file}:${toString __curPos.line}";

  passthru = {
    inherit payload childPlugins;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    # Keep all published launchers beside this copy of the executable.
    mkdir -p $out/lib $out/bin
    cp -r ${payload.passthru.unwrapped}/lib/pi-bolt $out/lib/pi-bolt
    chmod -R u+w $out/lib/pi-bolt
    cp ${payload}/lib/pi-bolt/${executable} $out/lib/pi-bolt/${executable}
    ${lib.optionalString (orchestratorAgentDir != null) ''
      cp ${payload}/lib/pi-bolt/pi-bolt-orchestrator $out/lib/pi-bolt/pi-bolt-orchestrator
    ''}
    cat > $out/lib/pi-bolt/pi-bolt-child <<'EOF'
    #!${runtimeShell}
    ${childEntrypoint}
    EOF
    chmod +x $out/lib/pi-bolt/pi-bolt-child
    ln -s ../lib/pi-bolt/${executable} $out/bin/${executable}
    ln -s ../lib/pi-bolt/pi-bolt-child $out/bin/pi-bolt-child
    ${lib.concatMapStringsSep "\n" (
      name:
      let
        target = if name == "pi" then executable else name;
      in
      "ln -s ../lib/pi-bolt/${target} $out/bin/${name}"
    ) extraBins}
    runHook postInstall
  '';

  # The copied payload is the AOT image the build produced: the same two skips
  # its own derivation needs, since stripping it damages the payload.
  dontStrip = true;
  dontPatchELF = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    # Every published name runs this output's payload, and `pi-bolt` resolves to
    # that name inside the executable's folder — the rule `doctor` reads.
    for name in ${executable} pi-bolt-child ${lib.concatStringsSep " " extraBins}; do
      target=$(readlink -f $out/bin/$name)
      case "$target" in
      "$out/lib/pi-bolt/"*) ;;
      *)
        echo "$name resolves outside the payload folder: $target" >&2
        exit 1
        ;;
      esac
    done
    [ "$(readlink -f $out/bin/${executable})" = "$out/lib/pi-bolt/${executable}" ]
    version=$(BUN_STATIC_HEAP_VERBOSE=1 $out/bin/${executable} --version 2>&1)
    printf '%s\n' "$version"
    grep -q 'image registered: true' <<< "$version"
    grep -q 'JIT on' <<< "$version"
    for pkg in ${lib.concatStringsSep " " (map toString tools)}; do
      grep -a -q "$pkg/bin" $out/lib/pi-bolt/${executable}
    done
    doctor=$(PI_OFFLINE=1 HOME=$TMPDIR PATH=$out/bin:$PATH $out/bin/${executable} doctor 2>&1 || true)
    grep -q '(this Pi-Bolt)' <<< "$doctor" || {
      echo "doctor does not report this installation as its own:"$'\n'"$doctor" >&2
      exit 1
    }
    ${lib.optionalString (plugins != { }) ''
      for id in ${lib.concatStringsSep " " (lib.attrNames plugins)}; do
        grep -q "builtin:$id" <<< "$doctor" || {
          echo "doctor does not list the compiled plugin $id:"$'\n'"$doctor" >&2
          exit 1
        }
      done
    ''}
    ${lib.optionalString (plugins ? omniroute) ''
      ${python3}/bin/python3 ${./test_entrypoints.py} "$out/lib/pi-bolt/pi" "$out/bin/pi-bolt-child"
    ''}
    runHook postInstallCheck
  '';
}
