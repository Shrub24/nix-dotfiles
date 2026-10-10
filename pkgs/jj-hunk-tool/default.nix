{
  lib,
  rustPlatform,
  fetchFromGitHub,
  jujutsu,
}:
rustPlatform.buildRustPackage {
  pname = "jj-hunk-tool";
  version = "0.1.0-unstable-20260918";

  src = fetchFromGitHub {
    owner = "mvzink";
    repo = "jj-hunk-tool";
    rev = "817a3d19cab8ed9bf04ebf64f2f3073fe195d641";
    hash = "sha256-HtuR2IL/WIq6+y8saHFAyquQ8cFGvvz0t3VqZXBQ7gI=";
  };

  cargoHash = "sha256-ncpm8g5In2Ih5cx3AnG2vPfGFy5oMnR012hBKqV4fYw=";

  nativeCheckInputs = [ jujutsu ];

  meta = {
    description = "Hunk-level operations for Jujutsu";
    homepage = "https://github.com/mvzink/jj-hunk-tool";
    license = lib.licenses.mit;
    mainProgram = "jj-hunk-tool";
  };
}
