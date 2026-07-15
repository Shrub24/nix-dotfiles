{
  dockerTools,
  lib,
  runCommand,
  writeShellScript,
}:

let
  ociImages = import ../../policy/oci-images.nix;
  ref = ociImages.litellm-database;

  # Parse "repo:tag@sha256:digest" into components
  atParts = lib.splitString "@" ref;
  imageDigest = lib.last atParts;
  repoTag = lib.head atParts;
  tagSep = builtins.match "([^:]+):(.+)" repoTag;
  imageName = builtins.elemAt tagSep 0;
  imageTag = builtins.elemAt tagSep 1;

  baseImage = dockerTools.pullImage {
    inherit imageName imageDigest;
    hash = "sha256-wnjXARKZqiJF+wbkMpOgM9gIoTfbtZpiocEkqMXPXRo=";
    finalImageTag = imageTag;
  };

  patchFiles = runCommand "litellm-patches" { } ''
    mkdir -p $out/patches
    cp ${./patches/streaming-empty-choices.patch} $out/patches/streaming-empty-choices.patch
    cp ${./patches/strip-prefix-message.patch} $out/patches/strip-prefix-message.patch
  '';

  # Custom entrypoint that applies patches then runs litellm
  entrypoint = writeShellScript "litellm-entrypoint" ''
    #! /bin/sh
    set -e

    LITELLM_DIR="/app/.venv/lib/python3.13/site-packages/litellm"
    PATCH_MARKER="$LITELLM_DIR/.patches_applied"

    # Apply patches once (idempotent)
    if [ ! -f "$PATCH_MARKER" ]; then
      cd "$LITELLM_DIR"
      patch -p1 < /patches/streaming-empty-choices.patch 2>/dev/null || true
      patch -p1 < /patches/strip-prefix-message.patch 2>/dev/null || true
      touch "$PATCH_MARKER"
    fi

    exec /app/.venv/bin/litellm --config /app/config.yaml --port "''${LITELLM_PORT:-4000}" "$@"
  '';

  ociImage = dockerTools.buildImage {
    name = "litellm-patched";
    fromImage = baseImage;
    tag = "latest";

    copyToRoot = [ patchFiles ];

    config = {
      Entrypoint = [ entrypoint ];
      ExposedPorts = {
        "4000/tcp" = { };
      };
    };
  };
in
ociImage
