{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  buildPythonPackage,
  pythonRelaxDepsHook,
  click,
  litellm,
  opentelemetry-api,
  pydantic,
  rich,
  tiktoken,
}:

buildPythonPackage rec {
  pname = "headroom-ai";
  version = "0.25.0";

  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/aa/cb/84969342e34fda736e8a8aa0bf614b46ffc2a4129011b7c66142faee26d0/headroom_ai-0.25.0-cp310-abi3-manylinux_2_28_x86_64.whl";
    hash = "sha256-ICrjH5N+iZMzlEGzY6Lkfrv0NQLiKkR7LGQ9OQhW9Nw=";
  };

  nativeBuildInputs = [
    pythonRelaxDepsHook
    autoPatchelfHook
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  pythonRelaxDeps = [ "litellm" ];
  pythonRemoveDeps = [ "ast-grep-cli" ];

  dependencies = [
    click
    litellm
    opentelemetry-api
    pydantic
    rich
    tiktoken
  ];

  pythonImportsCheck = [
    "headroom"
    "headroom.integrations.litellm_callback"
  ];

  meta = {
    description = "LLM context compression middleware with LiteLLM callback integration";
    homepage = "https://github.com/headroom-ai/headroom";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
