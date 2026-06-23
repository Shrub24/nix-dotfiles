{
  python3,
  litellm,
  headroom,
  prisma-engines_6,
  nodejs,
  cacert,
  fetchurl,
  runCommand,
  stdenv,
  writeText,
  writeShellScriptBin,
  lib,
}:

let
  prismaEngines = prisma-engines_6;
  pyVer = python3.pythonVersion;
  prismaPkg = python3.pkgs.prisma;

  # FOD: npm install prisma@5.17.0 with all transitive deps (network allowed)
  prismaNpmDeps = stdenv.mkDerivation {
    name = "prisma-npm-deps-5.17.0";
    nativeBuildInputs = [ nodejs ];
    buildInputs = [ cacert ];
    impureEnvVars = lib.fetchers.proxyImpureEnvVars;
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    NODE_EXTRA_CA_CERTS = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    buildCommand = ''
      export HOME=$TMPDIR
      mkdir -p $out
      cat > package.json <<'EOF'
      {"name":"prisma-binaries","version":"1.0.0","private":true,"main":"node_modules/prisma/build/index.js"}
      EOF
      npm install prisma@5.17.0 --ignore-scripts --no-audit --no-fund
      cp -r node_modules $out/node_modules
    '';
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-nms6e4bIOH61gfxjZLvaMc2ATWpGKFAEgl17dMRy+ho=";
  };

  # Python env with prisma + all its dependencies, for running `prisma generate`
  prismaPython = python3.withPackages (_: [ prismaPkg ]);

  # Pre-generate the Prisma client using LiteLLM's schema.prisma.
  prismaGenerated = runCommand "prisma-generated-client"
    {
      nativeBuildInputs = [ nodejs ];
      buildInputs = [ prismaPython prismaEngines ];
      PRISMA_QUERY_ENGINE_BINARY = "${prismaEngines}/bin/query-engine";
      PRISMA_SCHEMA_ENGINE_BINARY = "${prismaEngines}/bin/schema-engine";
      PRISMA_FMT_BINARY = "${prismaEngines}/bin/prisma-fmt";
      HOME = "/build";
    }
    ''
      # Copy prisma package to a writable location
      mkdir -p $out/lib/python${pyVer}/site-packages
      cp -r ${prismaPkg}/lib/python${pyVer}/site-packages/prisma \
        $out/lib/python${pyVer}/site-packages/prisma
      chmod -R +w $out

      # Pre-populate the npm cache so prisma CLI doesn't try to download
      cacheDir="/build/.cache/prisma-python/binaries/5.17.0/393aa359c9ad4a4bb28630fb5613f9c281cde053"
      mkdir -p "$cacheDir"
      cat > "$cacheDir/package.json" <<'EOF'
      {"name":"prisma-binaries","version":"1.0.0","private":true,"main":"node_modules/prisma/build/index.js"}
      EOF
      cp -r ${prismaNpmDeps}/node_modules "$cacheDir/node_modules"

      # Run prisma generate with LiteLLM's schema
      cd ${litellm}/lib/python${pyVer}/site-packages/litellm/proxy
      PYTHONPATH=$out/lib/python${pyVer}/site-packages \
        ${prismaPython}/bin/python -m prisma generate --schema=./schema.prisma
    '';

  python = python3.buildEnv.override {
    extraLibs =
      [
        litellm
        headroom
      ]
      ++ litellm.optional-dependencies.proxy
      ++ [
        python3.pkgs.opentelemetry-sdk
        python3.pkgs.opentelemetry-exporter-otlp
        python3.pkgs.prisma
      ];
    postBuild = ''
      # Replace prisma package with the pre-generated version
      rm -rf $out/lib/python${pyVer}/site-packages/prisma
      cp -r ${prismaGenerated}/lib/python${pyVer}/site-packages/prisma \
        $out/lib/python${pyVer}/site-packages/prisma
    '';
  };

  launcher = writeText "litellm-with-headroom.py" ''
    import argparse
    import os
    import subprocess
    import sys

    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=4000)
    args = parser.parse_args()

    os.environ["CONFIG_FILE_PATH"] = args.config

    # Auto-migrate Prisma schema when DATABASE_URL is set
    if os.environ.get("DATABASE_URL"):
        import litellm.proxy
        schema = os.path.join(os.path.dirname(litellm.proxy.__file__), "schema.prisma")
        if os.path.exists(schema):
            subprocess.run(
                [sys.executable, "-m", "prisma", "db", "push", f"--schema={schema}", "--accept-data-loss"],
                check=False,
            )

    from litellm.proxy.proxy_server import app
    from headroom.integrations.asgi import CompressionMiddleware
    import uvicorn

    app.add_middleware(CompressionMiddleware)
    uvicorn.run(app, host=args.host, port=args.port)
  '';
in
writeShellScriptBin "litellm" ''
  export PRISMA_QUERY_ENGINE_BINARY=''${PRISMA_QUERY_ENGINE_BINARY:-${prismaEngines}/bin/query-engine}
  export PRISMA_SCHEMA_ENGINE_BINARY=''${PRISMA_SCHEMA_ENGINE_BINARY:-${prismaEngines}/bin/schema-engine}
  export PRISMA_FMT_BINARY=''${PRISMA_FMT_BINARY:-${prismaEngines}/bin/prisma-fmt}
  exec ${python}/bin/python ${launcher} "$@"
''
