{
  python3,
  litellm,
  headroom,
  writeText,
  writeShellScriptBin,
}:

let
  python = python3.withPackages (
    _:
    [
      litellm
      headroom
    ]
    ++ litellm.optional-dependencies.proxy
    ++ [ python3.pkgs.opentelemetry-sdk python3.pkgs.opentelemetry-exporter-otlp ]
  );
  launcher = writeText "litellm-with-headroom.py" ''
    import argparse
    import os

    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=4000)
    args = parser.parse_args()

    os.environ["CONFIG_FILE_PATH"] = args.config

    from litellm.proxy.proxy_server import app
    from headroom.integrations.asgi import CompressionMiddleware
    import uvicorn

    app.add_middleware(CompressionMiddleware)
    uvicorn.run(app, host=args.host, port=args.port)
  '';
in
writeShellScriptBin "litellm" ''
  exec ${python}/bin/python ${launcher} "$@"
''
