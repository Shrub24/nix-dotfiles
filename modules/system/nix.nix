{ ... }:
{
  nix.enable = true;

  nix.settings = {
    "trusted-users" = [ "root" "saurabhj" ];
    "extra-substituters" = [
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
      "https://cache.shrublab.xyz"
    ];
    "trusted-substituters" = [
      "ssh-ng://eu.nixbuild.net"
    ];
    "extra-trusted-public-keys" = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-cache-1:FW0bJll9BP5ch0mHI+bXOImcD0RKLrH117WfQC+CU4A="
      "nixbuild.net/HWWKWC-1:dnSfpPDHQN/U9wexkK6r3GTaYrwqNwKS70SNGXistKg="
    ];
    "experimental-features" = [
      "nix-command"
      "flakes"
    ];
    "auto-optimise-store" = true;
    "always-allow-substitutes" = true;
    "builders-use-substitutes" = true;
    "max-jobs" = "auto";
    "extra-nix-path" = "nixpkgs=flake:nixpkgs";
    "keep-derivations" = true;
    "warn-dirty" = false;
    "accept-flake-config" = true;
  };
}
