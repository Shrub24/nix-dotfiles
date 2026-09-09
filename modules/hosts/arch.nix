{
  config,
  inputs,
  lib,
  ...
}:
let
  # The single typed account declaration; every consumer (HM, NixOS,
  # system-manager, VM, raw host modules) derives from it.
  primaryUser = {
    name = "saurabhj";
    uid = 1000;
    gid = 1000;
  };
  system = "x86_64-linux";
  overlay = import ../../pkgs { inherit inputs system; };
  # Applied to both the standalone HM pkgs and the NixOS global pkgs.
  unfreePredicate =
    pkg:
    (lib.hasPrefix "nvidia" (lib.getName pkg))
    || builtins.elem (lib.getName pkg) [
      "zsh-abbr"
      "byterover-cli"
      "vscode"
      "code"
      "unrar"
      "cuda_cuobjdump"
      "cuda_gdb"
      "cuda_nvcc"
      "cuda_nvdisasm"
      "cuda_nvprune"
      "cuda_cccl"
      "cuda_cudart"
      "cuda_cupti"
      "cuda_cuxxfilt"
      "cuda_nvrtc"
      "cuda_nvtx"
      "cuda_profiler_api"
      "cuda_sanitizer_api"
      "libcublas"
      "libcufft"
      "libnvjitlink"
      "libcurand"
      "libcusolver"
      "libcusparse"
      "libnpp"
      "cuda-merged"
      "cuda_nvml_dev"
      "nvidia-x11"
      "nvidia-settings"
      "nvidia-persistenced"
    ];
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ overlay ];
    config = {
      allowUnfreePredicate = unfreePredicate;
      nvidia.acceptLicense = true;
    };
  };
  pkgsUnfree = import inputs.nixpkgs {
    inherit system;
    overlays = [ overlay ];
    config.allowUnfree = true;
  };
  homepage = import ../../lib/web-services.nix {
    inherit (pkgs) lib;
  };
  hmAspect = name: config.flake.modules.homeManager.${name};
  systemAspect = name: config.flake.modules.systemManager.${name};
  nixosAspect = name: config.flake.modules.nixos.${name};
  hmAspects = [
    "pi"
    "herdr"
    "hermes"
    "tools"
    "dev-tools"
    "cli"
    "languages"
    "intelli-shell"
    "lazyjournal"
    "mise"
    "direnv"
    "monique"
    "niks3"
    "niri"
    "nix"
    "noctalia"
    "opencode"
    "portals"
    "fonts"
    "ghostty"
    "kde-apps"
    "pavucontrol"
    "libinput"
    "zathura"
    "media"
    "libreoffice"
    "util-apps"
    "syncthing"
    "surge"
    "ssh"
    "mutagen"
    "mosh"
    "tailscale"
    "vicinae"
    "audio"
    "brave-origin"
    "chromium"
    "credentials"
    "defaults"
    "firefox"
    "thunderbird"
    "vscode"
    "sops-foundation"
    "grist"
    "litellm"
    "docs-mcp"
    "modal"
    "qmd"
    "web-catalog"
    "shell"
    "fish"
    "zsh"
    "tmux"
    "wezterm"
    "kitty"
    "foot"
  ];
  # Full aspect set minus the system-owned duplicates the NixOS target provides
  # itself: tailscale/syncthing/mosh/surge/niks3. Plus the embedded-only
  # hardware aspects (cuda/libcamera) the standalone Arch host never selects.
  embeddedHmAspects =
    lib.subtractLists [
      "tailscale"
      "syncthing"
      "mosh"
      "surge"
      "niks3"
    ] hmAspects
    ++ [
      "cuda"
      "libcamera"
    ];
  systemAspects = [
    "network"
    "boot"
    "ssh"
    "tailscale"
    "greeter"
    "nix"
    "nixbuild"
  ];
  nixosAspects = [
    "foundation"
    "network"
    "boot"
    "ssh"
    "tailscale"
    "greeter"
    "nix"
    "nixbuild"
    "audio"
    "bluetooth"
    "power"
    "containers"
    "desktop-services"
    "kde-apps"
    "syncthing"
    "niks3"
    "mosh"
  ];
  homeConfiguration = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      (import ./arch/_home.nix { inherit primaryUser; })
      # Standalone-only: the embedded NixOS eval must not see these.
      {
        targets.genericLinux.gpu.nvidia = {
          enable = true;
          version = "610.57.04";
          sha256 = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
        };
        targets.genericLinux.enable = true;
        programs.niks3.enableAutoUploadService = true;
      }
    ]
    ++ map hmAspect hmAspects;
  };
  systemConfiguration = inputs.system-manager.lib.makeSystemConfig {
    modules = [ ./arch/_system.nix ] ++ map systemAspect systemAspects;
    overlays = [ overlay ];
  };
  nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      (import ./arch/_nixos.nix { inherit primaryUser; })
      { nixpkgs.overlays = [ overlay ]; } # same local overlay as systemConfiguration; aspects see pkgs.niks3-hook
      { nixpkgs.config.allowUnfreePredicate = unfreePredicate; }
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
              (import ./arch/_home.nix { inherit primaryUser; })
              { targets.genericLinux.enable = false; }
            ]
            ++ map hmAspect embeddedHmAspects;
          };
        };
      }
    ]
    ++ map nixosAspect nixosAspects;
  };
in
{
  config = {
    topology.hosts.arch = {
      inherit system;
      inherit primaryUser;
      remoteHosts = [
        "oci-melb-1"
        "home-forge"
        "la-admin-1"
      ];
    };
    topology.services.database.host = "oci-melb-1";
    topology.services.niks3.host = "http://oci-melb-1:5751";

    flake.homeConfigurations.${primaryUser.name} = homeConfiguration;

    flake.systemConfigs.arch = systemConfiguration;
    flake.nixosConfigurations.shrub = nixosConfiguration;

    flake.checks.${system} = {
      home-manager-activation = homeConfiguration.activationPackage;
      system-manager-config = systemConfiguration;
      nixos-system = nixosConfiguration.config.system.build.toplevel;

      # Agent-definition drift guard: pi-subagents treats a missing explicit
      # skill as an advisory warning, so a renamed or deleted skill would
      # silently under-instruct children. Fail eval instead.
      pi-agent-skills-referenced =
        let
          agentsDir = ../agents/pi/agents;
          skillsDir = ../agents/pi/skills;
          agentFiles = builtins.attrNames (
            lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (
              builtins.readDir agentsDir
            )
          );
          referenced = lib.unique (
            lib.flatten (
              map (
                agentFile:
                let
                  parts = lib.splitString "---" (builtins.readFile (agentsDir + "/${agentFile}"));
                  # File starts with ---, so the frontmatter is element 1.
                  frontmatter = lib.elemAt parts 1;
                  lines = lib.filter (line: lib.hasPrefix "skills:" line) (lib.splitString "\n" frontmatter);
                in
                map lib.trim (lib.flatten (map (line: lib.splitString "," (lib.removePrefix "skills:" line)) lines))
              ) agentFiles
            )
          );
          available = builtins.attrNames (
            lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
          );
          missing = lib.subtractLists available referenced;
        in
        if missing == [ ] then
          pkgs.runCommand "pi-agent-skills-referenced" { } "touch $out"
        else
          throw "pi agent files reference missing skills: ${lib.concatStringsSep ", " missing}";

      # VM boot gate: catches module-system conflicts that eval-only misses.
      vm-desktop = pkgsUnfree.testers.runNixOSTest {
        name = "vm-desktop";
        nodes.arch =
          { pkgs, ... }:
          {
            imports = map nixosAspect nixosAspects ++ [ inputs.home-manager.nixosModules.home-manager ];
            fileSystems."/" = {
              device = "/dev/vda";
              fsType = "ext4";
              autoFormat = true;
            };
            boot.loader.grub.device = "/dev/vda";
            boot.initrd.availableKernelModules = [ "virtio_blk" ];
            boot.initrd.kernelModules = [ "virtio_blk" ];
            virtualisation.graphics = true;
            virtualisation.memorySize = 4096;
            virtualisation.cores = 2;
            hardware.graphics.enable = true;
            services.btrfs.autoScrub.enable = pkgs.lib.mkForce false;
            services.niks3-auto-upload.enable = pkgs.lib.mkForce false;
            system.stateVersion = "26.11";
            networking.hostName = "shrub";
            users.users.${primaryUser.name}.initialPassword = "nixos";
            environment.pathsToLink = [
              "/share/applications"
              "/share/xdg-desktop-portal"
            ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${primaryUser.name} = {
                imports = map hmAspect [
                  "niri"
                  "noctalia"
                  "vicinae"
                  "portals"
                  "fonts"
                  "monique"
                  "shell"
                  "fish"
                  "zsh"
                  "tmux"
                  "wezterm"
                  "ghostty"
                  "kitty"
                  "foot"
                  "cli"
                  "ssh"
                  "kde-apps"
                  "pavucontrol"
                  "audio"
                  "libinput"
                  "zathura"
                  "firefox"
                  "brave-origin"
                  "defaults"
                  "vscode"
                ];
                home.username = primaryUser.name;
                home.homeDirectory = "/home/${primaryUser.name}";
                home.stateVersion = "26.11";
                # VM-only: virglrenderer 1.3.0 draws the hardware cursor plane
                # upside-down (QEMU #2315, fixed upstream in virgl 1.3.1) — drop then.
                wayland.windowManager.niri.settings.debug."disable-cursor-plane" = { };
              };
            };
          };
        testScript = ''
          arch.start()
          arch.wait_for_unit("multi-user.target")
          arch.wait_for_unit("home-manager-${primaryUser.name}.service")
          arch.wait_for_unit("greetd.service")
          # greetd.active != greeter ready: cage + greeter need seconds more to
          # map the first frame, and keys sent before that are dropped.
          arch.wait_until_succeeds("journalctl -b --no-pager | grep -q 'greeter initialized'", timeout=120)
          arch.sleep(2)
          arch.screenshot("greeter")
          arch.send_chars("nixos")
          arch.send_key("ret")
          arch.wait_until_succeeds("pgrep -x niri")
          arch.screenshot("desktop")
        '';
      };

      vm-skeleton-boot = pkgs.testers.runNixOSTest {
        name = "vm-skeleton-boot";
        nodes.arch = {
          imports = map nixosAspect nixosAspects;
          system.stateVersion = "26.11";
          networking.hostName = "shrub";
          fileSystems."/" = {
            device = "/dev/vda";
            fsType = "ext4";
            autoFormat = true;
          };
          boot.loader.grub.device = "/dev/vda";
          boot.initrd.availableKernelModules = [ "virtio_blk" ];
          boot.initrd.kernelModules = [ "virtio_blk" ];
          virtualisation.graphics = false;
          services.btrfs.autoScrub.enable = pkgs.lib.mkForce false;
          services.niks3-auto-upload.enable = pkgs.lib.mkForce false;
        };
        testScript = ''
          arch.start()
          arch.wait_for_unit("multi-user.target")
          arch.succeed("nix-store --version")
          # nix-daemon is socket-activated and idle until a client connects, and
          # root talks to the local store without touching it — force a real
          # daemon round-trip so the unit actually starts.
          arch.succeed("nix --store daemon store ping")
          arch.wait_for_unit("nix-daemon.service")

          arch.wait_for_unit("tailscaled.service")
          arch.wait_for_unit("systemd-resolved.service")
          arch.wait_for_unit("NetworkManager.service")
          arch.wait_for_unit("avahi-daemon.service")
          arch.wait_for_unit("sshd.service")
          arch.wait_for_unit("acpid.service")
          # DBus-activated; no disks in a headless VM, so assert the unit exists
          # rather than waiting for it to run.
          arch.succeed("systemctl cat udisks2.service")
        '';
      };
    };

    flake.webServices = homepage.catalog;
    flake.webServiceCatalog = homepage.normalize homepage.catalog;
    flake.webServiceCatalogJSON = pkgs.writeText "web-service-catalog.json" (
      builtins.toJSON (homepage.toCatalogJSON homepage.catalog)
    );
  };
}
