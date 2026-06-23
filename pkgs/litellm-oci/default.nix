{
  dockerTools,
  lib,
  runCommand,
  writeShellScript,
  writeShellScriptBin,
  writeText,
  streaming-patch,
  strip-prefix-patch,
}:

let
  baseImage = dockerTools.pullImage {
    imageName = "ghcr.io/berriai/litellm-database";
    imageDigest = "sha256:598664e0bed053e774d5dbd18745ddce890e8c6909390ccf669beae443a9d984";
    hash = "sha256-/9K1dpdydpAeL1G3FcG+EJYVnwpIff9d6Sb+JTO9pO0=";
    finalImageTag = "v1.89.3";
  };

  patchFiles = runCommand "litellm-patches" { } ''
    mkdir -p $out/patches
    cp ${streaming-patch} $out/patches/streaming-empty-choices.patch
    cp ${strip-prefix-patch} $out/patches/strip-prefix-message.patch
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

    # Run prisma generate + db push if DATABASE_URL is set
    if [ -n "''${DATABASE_URL:-}" ]; then
      PRISMA_SCHEMA="/app/.venv/lib/python3.13/site-packages/litellm/proxy/schema.prisma"
      /app/.venv/bin/prisma generate --schema "$PRISMA_SCHEMA" 2>/dev/null || true
      /app/.venv/bin/prisma db push --schema "$PRISMA_SCHEMA" --accept-data-loss 2>/dev/null || true
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
      ExposedPorts = { "4000/tcp" = { }; };
    };
  };
in
ociImage
