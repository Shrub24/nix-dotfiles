{
  config,
  inputs,
  lib,
  ...
}:
let
  primaryUser = {
    name = "saurabhj";
    uid = 1000;
    gid = 1000;
  };
  system = "x86_64-linux";
  hostId = "spectre";
  # Evaluation-local projection: features read config.currentHost, so one aspect
  # value serves every host and only the composition names "self".
  currentHost = {
    id = hostId;
    inherit primaryUser;
    peers = lib.removeAttrs config.topology.hosts [ hostId ];
  };
  currentHostModule = { inherit currentHost; };
  overlay = import ../../pkgs { inherit inputs system; };
  pkgsUnfree = import inputs.nixpkgs {
    inherit system;
    overlays = [ overlay ];
    config.allowUnfree = true;
  };
  hmAspect = name: config.flake.modules.homeManager.${name};
  nixosAspect = name: config.flake.modules.nixos.${name};

  # Lean portable profile: no local service tier; memory is the binding
  # constraint on 8 GB of soldered RAM.
  hmAspects = [
    "current-host"
    "pi"
    "herdr"
    "dev-tools"
    "lsp"
    "nvim"
    "cli"
    "languages"
    "intelli-shell"
    "lazyjournal"
    "mise"
    "direnv"
    "niri"
    "nix"
    "noctalia"
    "portals"
    "fonts"
    "libinput"
    "audio"
    "pavucontrol"
    "kde-apps"
    "util-apps"
    "defaults"
    "shell"
    "fish"
    "tmux"
    "wezterm"
    "kitty"
    "foot"
    "ssh"
    "mosh"
    "tailscale"
    "sops-foundation"
    "credentials"
    "firefox"
    "thunderbird"
    "zathura"
  ];

  # Phase 1 of the secrets bootstrap: the machine installs and
  # switches without any secret-consuming aspect, because sops activation fails
  # when no key can decrypt. Phase 2 adds "sops-foundation", "credentials", and
  # "nix" (whose HM value renders the GITHUB_PAT access-token file) once the
  # host's age key is generated and the secrets are re-encrypted for it.
  hmAspectsPhase1 = lib.subtractLists [
    "sops-foundation"
    "credentials"
    "nix"
  ] hmAspects;

  nixosAspects = [
    "current-host"
    "foundation"
    "network"
    "boot"
    "ssh"
    "tailscale"
    "greeter"
    "nix"
    "audio"
    "bluetooth"
    "power"
    "containers"
    "desktop-services"
    "kde-apps"
    "mosh"
  ];

  nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      currentHostModule
      (import ./spectre/_nixos.nix { inherit primaryUser; })
      { nixpkgs.overlays = [ overlay ]; }
      {
        # The one unfree package the lean set pulls in (unrar, via the cli
        # aspect). The desktop's NVIDIA predicate list is desktop-only and
        # deliberately not inherited.
        nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "unrar";
      }
      inputs.home-manager.nixosModules.home-manager
      {
        # Home Manager via useUserPackages + xdg.portal needs this (home-manager assertion).
        environment.pathsToLink = [
          "/share/applications"
          "/share/xdg-desktop-portal"
        ];
      }
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${primaryUser.name} = {
            imports = [
              currentHostModule
              (import ./spectre/_home.nix { inherit primaryUser; })
            ]
            ++ map hmAspect (if secretsEnrolled then hmAspects else hmAspectsPhase1);
          };
        };
      }
    ]
    ++ map nixosAspect nixosAspects;
  };

  # Phase 1 → phase 2 flip. While the
  # host's age key is not yet a recipient in .sops.yaml, the switch would fail
  # on the secret-consuming aspects; the composition then omits them. After
  # `sops updatekeys` has run from the desktop, set this to true and switch
  # again — the only edit install day makes to this file.
  secretsEnrolled = false;
in
{
  config = {
    # This machine's own registry entry. Fleet entries and service endpoints
    # live beside the schema in modules/policy/topology.nix.
    topology.hosts.${hostId} = {
      inherit system;
      inherit primaryUser;
      sshUser = primaryUser.name;
    };

    flake.nixosConfigurations.${hostId} = nixosConfiguration;

    flake.checks.${system} = {
      nixos-spectre = nixosConfiguration.config.system.build.toplevel;

      # Boot-level gate for the laptop's aspect composition (design D9):
      # eval-only checking has already proven insufficient in this repository.
      # Headless, no greeter, no graphical assertions — the point is that the
      # selected aspects coexist and the machine boots.
      vm-spectre-boot = pkgsUnfree.testers.runNixOSTest {
        name = "vm-spectre-boot";
        nodes.spectre = {
          imports = map nixosAspect nixosAspects ++ [
            currentHostModule
            inputs.home-manager.nixosModules.home-manager
          ];
          fileSystems."/" = {
            device = "/dev/vda";
            fsType = "ext4";
            autoFormat = true;
          };
          boot.loader.grub.device = "/dev/vda";
          boot.initrd.availableKernelModules = [ "virtio_blk" ];
          boot.initrd.kernelModules = [ "virtio_blk" ];
          virtualisation.graphics = false;
          services.btrfs.autoScrub.enable = lib.mkForce false;
          system.stateVersion = "26.11";
          networking.hostName = "spectre";
          users.users.${primaryUser.name}.initialPassword = "nixos";
          environment.pathsToLink = [
            "/share/applications"
            "/share/xdg-desktop-portal"
          ];
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${primaryUser.name} = {
              imports = [
                currentHostModule
                (import ./spectre/_home.nix { inherit primaryUser; })
              ]
              ++ map hmAspect (if secretsEnrolled then hmAspects else hmAspectsPhase1);
              home.username = primaryUser.name;
              home.homeDirectory = "/home/${primaryUser.name}";
              home.stateVersion = "26.11";
            };
          };
        };
        testScript = ''
          spectre.start()
          spectre.wait_for_unit("multi-user.target")
          spectre.succeed("nix-store --version")
          spectre.succeed("nix --store daemon store ping")
          spectre.wait_for_unit("nix-daemon.service")
          spectre.wait_for_unit("tailscaled.service")
          spectre.wait_for_unit("systemd-resolved.service")
          spectre.wait_for_unit("NetworkManager.service")
          spectre.wait_for_unit("sshd.service")
          spectre.wait_for_unit("home-manager-${primaryUser.name}.service")
        '';
      };
    };
  };
}
