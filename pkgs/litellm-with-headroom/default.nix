{
  python3,
  litellm,
  writeText,
  writeShellScriptBin,
}:

let
  headroom = python3.pkgs.callPackage ../headroom-ai { };
  python = python3.withPackages (
    _:
    [
      litellm
      headroom
    ]
    ++ litellm.optional-dependencies.proxy
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
