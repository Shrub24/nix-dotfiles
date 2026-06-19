{
  version,
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

buildPythonPackage {
  pname = "headroom-ai";
  inherit version;

  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/64/6f/14cc372e9a6ac6704c219ad106a7fc19d864dd040c31247923a9c8157600/headroom_ai-0.26.0-cp310-abi3-manylinux_2_28_x86_64.whl";
    hash = "sha256-tsIOtq9CaX4arMmxv9EC2VFeFlZzNU61dRdHOhfBWyg=";
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
