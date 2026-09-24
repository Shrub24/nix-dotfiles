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
  hostId = "legion";
  # Evaluation-local projection: features read config.currentHost, so one aspect
  # value serves every host and only the composition names "self".
  currentHost = {
    id = hostId;
    inherit primaryUser;
    peers = lib.removeAttrs config.topology.hosts [ hostId ];
  };
  currentHostModule = { inherit currentHost; };
  omniroute = config.topology.services.omniroute.host;
  # Build dispatch: nix-fleet's pure resolver turns the canonical inventory and
  # this repository's profile into normalized specs, and nixpkgs renders them
  # into /etc/nix/machines. The private key is a credential reference the
  # resolver deliberately leaves null — the coordinator's dispatch key is
  # root-owned — so the composition fills it in.
  dispatch = inputs.nix-fleet.lib.buildProfile;
  dispatchSpecs = map (spec: spec // { sshKeyPath = "/root/.ssh/nix-remote"; }) (
    dispatch.resolveBuildProfile config.fleet "workstations"
  );
  # Which fleet hosts this machine trusts and talks to. nix-fleet owns the
  # records — hostnames, host keys, management account; the selection is host
  # policy. Trust is its own door, so naming a host here never makes it
  # schedulable. Multiplexing is a property of the connections this machine
  # actually makes, so it rides the selection rather than the global block.
  sshOptions = {
    ControlMaster = "auto";
  };
  sshTrust = dispatch.resolveHosts config.fleet {
    home-forge = { inherit sshOptions; };
    la-admin-1 = { inherit sshOptions; };
    oci-melb-1 = { inherit sshOptions; };
    spectre = { inherit sshOptions; };
  };
  sshTrustModule = { inherit sshTrust; };
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
    "current-host"
    "pi"
    "herdr"
    "hermes"
    "tools"
    "memex"
    "dev-tools"
    "lsp"
    "nvim"
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
  # Full set minus the system-owned duplicates NixOS provides itself
  # (tailscale/syncthing/mosh/niks3), plus the embedded-only hardware aspects.
  embeddedHmAspects =
    lib.subtractLists [
      "tailscale"
      "syncthing"
      "mosh"
      "niks3"
    ] hmAspects
    ++ [
      "cuda"
      "libcamera"
    ];
  # Arch boot configuration is machine-specific (dracut drop-in, Limine conf) and
  # lives in the host's own raw module (modules/hosts/legion/_system.nix), so there
  # is no shared systemManager boot aspect.
  systemAspects = [
    "current-host"
    "network"
    "ssh"
    "tailscale"
    "greeter"
    "nix"
    "nixbuild"
  ];
  nixosAspects = [
    "current-host"
    "foundation"
    "network"
    "boot"
    "ssh"
    "tailscale"
    "greeter"
    "nix"
    "notify"
    "beszel-agent"
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
      currentHostModule
      sshTrustModule
      (import ./legion/_home.nix { inherit omniroute primaryUser; })
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
    modules = [
      currentHostModule
      sshTrustModule
      # systemManager has no nix.buildMachines (#466), so the resolved dispatch
      # specs render into /etc/nix/machines directly.
      {
        environment.etc."nix/machines" = {
          text = dispatch.machinesFile dispatchSpecs;
          mode = "0644";
        };
      }
      ./legion/_system.nix
    ]
    ++ map systemAspect systemAspects;
    overlays = [ overlay ];
  };
  nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      currentHostModule
      sshTrustModule
      (import ./legion/_nixos.nix { inherit primaryUser; })
      { nixpkgs.overlays = [ overlay ]; } # same local overlay as systemConfiguration
      { nixpkgs.config.allowUnfreePredicate = unfreePredicate; }
      # Which builders this host schedules is composition policy, resolved from
      # the canonical inventory rather than restated here.
      {
        nix.distributedBuilds = true;
        nix.buildMachines = dispatch.buildMachines dispatchSpecs;
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
              sshTrustModule
              (import ./legion/_home.nix { inherit omniroute primaryUser; })
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
    # This machine's own registry entry. Fleet entries and service endpoints
    # live beside the schema in modules/policy/topology.nix.
    topology.hosts.${hostId} = {
      inherit primaryUser;
      sshUser = primaryUser.name;
    };

    flake.homeConfigurations.${primaryUser.name} = homeConfiguration;

    flake.systemConfigs.legion = systemConfiguration;
    flake.nixosConfigurations.legion = nixosConfiguration;

    flake.checks.${system} = {
      home-manager-activation = homeConfiguration.activationPackage;
      system-manager-config = systemConfiguration;
      nixos-system = nixosConfiguration.config.system.build.toplevel;

      # Agent-definition drift guard: pi-subagents treats a missing explicit
      # skill as an advisory warning, so a renamed or deleted skill would
      # silently under-instruct children. Fail eval instead.
      # Skills may live in the repo skills dir OR the user-global
      # ~/.agents/skills discovery root (cross-tool home: ast-grep,
      # codebase-memory, ...). Globals are declared here explicitly so a
      # rename still fails eval; repo skills are checked against skillsDir.
      pi-agent-skills-referenced =
        let
          agentsDir = ../agents/pi/agents;
          skillsDir = ../agents/pi/skills;
          globalSkills = [
            "ast-grep"
            "codebase-memory"
            "codebase-design"
            "code-review"
            "dendritic-nix"
            "diagnose"
            "docs-search"
            "domain-modeling"
            "find-skills"
            "grilling"
            "implement"
            "jj"
            "nh"
            "nix-toolkit"
            "qmd"
            "review-local-changes"
            "tdd"
            "writing-for-agents"
            "xberg"
          ];
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
          available =
            builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir))
            ++ globalSkills;
          missing = lib.subtractLists available referenced;
        in
        if missing == [ ] then
          pkgs.runCommand "pi-agent-skills-referenced" { } "touch $out"
        else
          throw "pi agent files reference missing skills: ${lib.concatStringsSep ", " missing}";

      # VM boot gate: catches module-system conflicts that eval-only misses.
      vm-desktop = pkgsUnfree.testers.runNixOSTest {
        name = "vm-desktop";
        nodes.legion =
          { pkgs, ... }:
          {
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
            virtualisation.graphics = true;
            virtualisation.memorySize = 4096;
            virtualisation.cores = 2;
            hardware.graphics.enable = true;
            services.btrfs.autoScrub.enable = pkgs.lib.mkForce false;
            services.niks3-auto-upload.enable = pkgs.lib.mkForce false;
            # No age key inside the VM: keep the registration, drop the secret.
            services.notify.secretFiles.hostSystem = pkgs.lib.mkForce null;
            system.stateVersion = "26.11";
            networking.hostName = "legion";
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
                ]
                ++ map hmAspect [
                  "current-host"
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
          legion.start()
          legion.wait_for_unit("multi-user.target")
          legion.wait_for_unit("home-manager-${primaryUser.name}.service")
          legion.wait_for_unit("greetd.service")
          # greetd.active != greeter ready: cage + greeter need seconds more to
          # map the first frame, and keys sent before that are dropped.
          legion.wait_until_succeeds("journalctl -b --no-pager | grep -q 'greeter initialized'", timeout=120)
          legion.sleep(2)
          legion.screenshot("greeter")
          legion.send_chars("nixos")
          legion.send_key("ret")
          legion.wait_until_succeeds("pgrep -x niri")
          legion.screenshot("desktop")
        '';
      };

      vm-skeleton-boot = pkgs.testers.runNixOSTest {
        name = "vm-skeleton-boot";
        nodes.legion = {
          imports = map nixosAspect nixosAspects ++ [ currentHostModule ];
          system.stateVersion = "26.11";
          networking.hostName = "legion";
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
          legion.start()
          legion.wait_for_unit("multi-user.target")
          legion.succeed("nix-store --version")
          # nix-daemon is socket-activated and idle until a client connects, and
          # root talks to the local store without touching it — force a real
          # daemon round-trip so the unit actually starts.
          legion.succeed("nix --store daemon store ping")
          legion.wait_for_unit("nix-daemon.service")

          legion.wait_for_unit("tailscaled.service")
          legion.wait_for_unit("systemd-resolved.service")
          legion.wait_for_unit("NetworkManager.service")
          legion.wait_for_unit("avahi-daemon.service")
          legion.wait_for_unit("sshd.service")
          legion.wait_for_unit("acpid.service")
          # DBus-activated; no disks in a headless VM, so assert the unit exists
          # rather than waiting for it to run.
          legion.succeed("systemctl cat udisks2.service")
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
