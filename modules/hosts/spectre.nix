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
  currentHost = {
    id = hostId;
    inherit primaryUser;
    peers = lib.removeAttrs config.topology.hosts [ hostId ];
  };
  currentHostModule = { inherit currentHost; };
  dispatch = inputs.nix-fleet.lib.buildProfile;
  # Which fleet hosts the laptop trusts is host policy; multiplexing rides the
  # selection rather than the global block.
  sshOptions = {
    ControlMaster = "auto";
  };
  sshTrust = dispatch.resolveHosts config.fleet {
    legion = { inherit sshOptions; };
    home-forge = { inherit sshOptions; };
    la-admin-1 = { inherit sshOptions; };
    oci-melb-1 = { inherit sshOptions; };
  };
  sshTrustModule = { inherit sshTrust; };
  overlay = import ../../pkgs { inherit inputs system; };
  pkgsUnfree = import inputs.nixpkgs {
    inherit system;
    overlays = [ overlay ];
    config.allowUnfree = true;
  };
  hmAspect = name: config.flake.modules.homeManager.${name};
  nixosAspect = name: config.flake.modules.nixos.${name};

  # Lean portable profile — deliberate omissions, not drift: the service tier is
  # reached over the tailnet, the desktop-only apps are not installed here, and
  # mcp-nixos is wired for its client only (its daemon stays off).
  hmAspects = [
    "current-host"
    "pi"
    "magic-context"
    "mcp-nixos"
    "herdr"
    "dev-tools"
    "lsp"
    "nvim"
    "cli"
    "git"
    "languages"
    "intelli-shell"
    "lazyjournal"
    "mise"
    "direnv"
    "monique"
    "niri"
    "nix"
    "noctalia"
    "vicinae"
    "portals"
    "fonts"
    "libinput"
    "audio"
    "pavucontrol"
    "kde-apps"
    "libreoffice"
    "util-apps"
    "defaults"
    "shell"
    "fish"
    "starship"
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

  # Phase 1: sops activation fails when no key can decrypt, so the
  # secret-consuming aspects wait for the host's age key to be a recipient.
  hmAspectsPhase1 = lib.subtractLists [
    "sops-foundation"
    "credentials"
    "nix"
  ] hmAspects;

  nixosAspects = [
    "current-host"
    "foundation"
    "fish"
    "network"
    "globalprotect"
    "boot"
    "ssh"
    "tailscale"
    "greeter"
    "nix"
    "notify"
    "beszel-agent"
    "audio"
    "bluetooth"
    "power"
    "containers"
    "desktop-services"
    "kde-apps"
    "wireshark"
    "mosh"
  ];

  # notify registers a system secret, so phase 1 omits it too; beszel-agent
  # is not gated — it holds only the hub's public key.
  nixosAspectsPhase1 = lib.subtractLists [
    "notify"
  ] nixosAspects;

  nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      currentHostModule
      sshTrustModule
      (import ./spectre/_nixos.nix { inherit primaryUser; })
      # disko owns the mounts, the LUKS initrd device and swap on this host:
      # _hardware.nix declares policy, _disko.nix declares the disk.
      inputs.disko.nixosModules.disko
      (import ./spectre/_disko.nix { })
      { nixpkgs.overlays = [ overlay ]; }
      {
        # The lean set's only unfree package (unrar, via cli); the desktop's
        # NVIDIA predicate list is deliberately not inherited.
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
          # Without this, a pre-existing unmanaged file at an HM target aborts
          # the first activation instead of being moved aside.
          backupFileExtension = "backup";
          users.${primaryUser.name} = {
            imports = [
              currentHostModule
              sshTrustModule
              (import ./spectre/_home.nix { inherit primaryUser; })
            ]
            ++ map hmAspect (if secretsEnrolled then hmAspects else hmAspectsPhase1);
          };
        };
      }
    ]
    ++ map nixosAspect (if secretsEnrolled then nixosAspects else nixosAspectsPhase1)
    ++ lib.optionals secretsEnrolled [
      # The embedded Home Manager's activation unit; host evals only.
      { services.notify.events."home-manager-${primaryUser.name}".failure.severity = "critical"; }
    ];
  };

  # Phase 1 → phase 2 flip: set true once `sops updatekeys` has run from the
  # desktop and the host's age key is a recipient in .sops.yaml. This is the
  # only edit install day makes to this file.
  secretsEnrolled = false;
in
{
  config = {
    # This machine's registry entry; the rest live in the topology schema.
    topology.hosts.${hostId} = {
      inherit primaryUser;
      sshUser = primaryUser.name;
    };

    flake.nixosConfigurations.${hostId} = nixosConfiguration;

    flake.checks.${system} = {
      nixos-spectre = nixosConfiguration.config.system.build.toplevel;

      # Boot-level gate for the composition: eval-only checking has proven
      # insufficient here. Headless — the point is that it boots.
      vm-spectre-boot = pkgsUnfree.testers.runNixOSTest {
        name = "vm-spectre-boot";
        nodes.spectre = {
          imports = map nixosAspect nixosAspectsPhase1 ++ [
            currentHostModule
            sshTrustModule
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
                sshTrustModule
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
