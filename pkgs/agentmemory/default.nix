{
  lib,
  buildNpmPackage,
  fetchurl,
  makeWrapper,
  iii-engine,
  version,
  srcHash,
  npmDepsHash,
}:

buildNpmPackage rec {
  pname = "agentmemory";
  inherit version npmDepsHash;

  src = fetchurl {
    url = "https://registry.npmjs.org/@agentmemory/agentmemory/-/agentmemory-${version}.tgz";
    hash = srcHash;
  };

  sourceRoot = "package";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmFlags = [
    "--legacy-peer-deps"
    "--ignore-scripts"
  ];
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/agentmemory \
      --prefix PATH : ${lib.makeBinPath [ iii-engine ]}
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Persistent memory for AI coding agents — powered by iii-engine";
    homepage = "https://github.com/rohitg00/agentmemory";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
