{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

let
  pname = "snip";
  version = "0.17.0";
in
buildGoModule (finalAttrs: {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "edouard-claude";
    repo = pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-YPdOXJ2YavJijdXHBnqMKEorBv2jDSZxwhzRig8HXvk=";
  };

  vendorHash = "sha256-2MxFZqjNuLzcuu+bsLyOyHIakCxh7j0FUx8LsjZRhrY=";

  subPackages = [ "cmd/snip" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/edouard-claude/snip/internal/cli.version=${finalAttrs.version}"
  ];

  meta = {
    description = "Config-driven CLI filter that compresses command output before it reaches an LLM context";
    homepage = "https://github.com/edouard-claude/snip";
    changelog = "https://github.com/edouard-claude/snip/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "snip";
    platforms = lib.platforms.linux;
  };
})
