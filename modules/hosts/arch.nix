{
  config,
  inputs,
  ...
}:
let
  # Host-local literals for the Arch desktop host (B11: former facts folded out
  # into topology + these literals; _facts.nix removed).
  primaryUser = "saurabhj";
  system = "x86_64-linux";
  overlay = import ../../pkgs { inherit inputs system; };
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ overlay ];
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
    "ssh"
    "mutagen"
    "mosh"
    "tailscale"
    "vicinae"
    "audio"
    "brave"
    "chromium"
    "credentials"
    "firefox"
    "thunderbird"
    "vscode"
    "sops-foundation"
    "grist"
    "litellm"
    "docs-mcp"
    "qmd"
    "web-catalog"
    "shell"
    "fish"
    "zsh"
    "tmux"
    "wezterm"
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
    "syncthing"
  ];
  homeConfiguration = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [ ./arch/_home.nix ] ++ map hmAspect hmAspects;
  };
  systemConfiguration = inputs.system-manager.lib.makeSystemConfig {
    modules = [ ./arch/_system.nix ] ++ map systemAspect systemAspects;
    overlays = [ overlay ];
  };
  nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ./arch/_nixos.nix
      { nixpkgs.overlays = [ overlay ]; } # same local overlay as systemConfiguration; aspects see pkgs.niks3-hook
    ]
    ++ map nixosAspect nixosAspects;
    specialArgs = { }; # empty — NO inputs/hostFacts bus; maintain cleanup invariant
  };
in
{
  config = {
    # Typed topology (B2/B11): host + service facts now live here, read via
    # `config.topology` by feature modules — not through an argument-passing bus.
    topology.hosts.arch = {
      inherit system;
      primaryUser = primaryUser;
      remoteHosts = [
        "oci-melb-1"
        "do-admin-1"
        "la-admin-1"
      ];
    };
    topology.services.database.host = "oci-melb-1";
    topology.services.niks3.host = "http://oci-melb-1:5751";

    flake.homeConfigurations.${primaryUser} = homeConfiguration;

    flake.systemConfigs.arch = systemConfiguration;
    flake.nixosConfigurations.arch = nixosConfiguration;

    # Forces full eval of all configurations under nix flake check without switching.
    flake.checks.${system} = {
      home-manager-activation = homeConfiguration.activationPackage;
      system-manager-config = systemConfiguration;
      nixos-system = nixosConfiguration.config.system.build.toplevel;

      # VM boot gate: imports the SAME aspects as nixosConfigurations.arch so this
      # catches NixOS module-system conflicts (a unit wanting a path that doesn't
      # exist, a mkIf turning false, a circular systemd dep) that eval-only misses.
      vm-desktop = pkgsUnfree.testers.runNixOSTest {
        name = "vm-desktop";
        nodes.arch = { ... }: {
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
          system.stateVersion = "26.11";
          networking.hostName = "arch";
          # Host pkgs for this test is pkgsUnfree (allowUnfree), so nixpkgs.config inside the VM is consistent.
          users.users.saurabhj = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            initialPassword = "nixos";
          };
          environment.pathsToLink = [
            "/share/applications"
            "/share/xdg-desktop-portal"
          ];
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.saurabhj = {
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
                "cli"
                "ssh"
                "kde-apps"
                "pavucontrol"
                "audio"
                "libinput"
                "zathura"
                "firefox"
                "brave"
                "vscode"
              ];
              home.username = "saurabhj";
              home.homeDirectory = "/home/saurabhj";
              home.stateVersion = "26.11";
            };
          };
        };
        testScript = ''
          arch.start()
          arch.wait_for_unit("multi-user.target")
          arch.wait_for_unit("greetd.service")
          arch.sleep(5)
          arch.screenshot("greeter")
          # Manual UX testing: the QEMU window stays open. For interactive use,
          # build .#checks.x86_64-linux.vm-desktop.driverInteractive and run
          # ./result/bin/nixos-test-driver (then start_all() etc).
        '';
      };

      vm-skeleton-boot = pkgs.testers.runNixOSTest {
        name = "vm-skeleton-boot";
        nodes.arch = {
          imports = map nixosAspect nixosAspects;
          # Host-local literals (mirror _nixos.nix):
          system.stateVersion = "26.11";
          networking.hostName = "arch";
          # nixpkgs.hostPlatform NOT set here: runNixOSTest pins node.pkgs (= pkgsLinux, the overlayed
          # pkgs incl. pkgs.niks3-hook) as read-only, which already fixes platform + overlay.
          users.users.${primaryUser} = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
          # VM hardware (replaces _hardware.nix; QEMU disk + grub, headless):
          fileSystems."/" = {
            device = "/dev/vda";
            fsType = "ext4";
            autoFormat = true;
          };
          boot.loader.grub.device = "/dev/vda";
          boot.initrd.availableKernelModules = [ "virtio_blk" ];
          boot.initrd.kernelModules = [ "virtio_blk" ];
          virtualisation.graphics = false;
          services.btrfs.autoScrub.enable = pkgs.lib.mkForce false; # VM uses ext4, not btrfs — no scrub target
        };
        testScript = ''
          arch.start()
          arch.wait_for_unit("multi-user.target")
          arch.succeed("nix-store --version")
          # nix-daemon.service is SOCKET-ACTIVATED on NixOS (wanted by sockets.target) and sits idle
          # until a client connects. Also, nix run as root talks to the LOCAL store (root can write
          # /nix/store directly), which never touches the daemon. So force a real daemon round-trip
          # via the daemon store, which triggers socket-activation and starts nix-daemon.service.
          arch.succeed("nix --store daemon store ping")
          arch.wait_for_unit("nix-daemon.service")

          # tailscale side-port: native services.tailscale runs tailscaled.service.
          arch.wait_for_unit("tailscaled.service")

          # network side-port: services.resolved enable -> systemd-resolved.service.
          arch.wait_for_unit("systemd-resolved.service")

          # NetworkManager (network aspect)
          arch.wait_for_unit("NetworkManager.service")

          # Avahi mDNS (network aspect)
          arch.wait_for_unit("avahi-daemon.service")

          # SSH server (ssh aspect)
          arch.wait_for_unit("sshd.service")

          # ACPI event daemon (power aspect)
          arch.wait_for_unit("acpid.service")
          # udisks2 is DBus-activated, not auto-started in headless VM with no disks — verify unit exists but don't wait for active
          arch.succeed("systemctl cat udisks2.service")

          # Skipped (documented):
          #  - bluetooth: no bluetooth controller in QEMU
          #  - pipewire: user-scoped on NixOS (no user session in headless VM)
          #  - podman: socket-activated, heavy; eval-tested, not runtime-tested here
          #  - plymouth: graphics
          #  - upower/power-profiles-daemon: no battery/power hardware in QEMU
          #  - gnome-keyring: user session
          #  - openrazer: no Razer hardware
          #  - snapper: VM uses ext4, not btrfs
          #  - printing/cups: socket-activated, needs print spooler interaction

          # Skipped assertions (documented):
          #  - ssh aspect is client-only (no server) -> nothing to assert.
          #  - boot aspect is a no-op; systemd-boot is a bootloader, not a runtime service.
          #  - greeter side-port: polkit.service is socket/DBus-activated and sits idle in a
          #    headless VM with no polkit client, so it never reaches active -> not asserted here
          #    (likewise greetd.service needs graphics/DRI to run; sops-install-secrets.service
          #    needs the sops key path + secrets that don't exist in CI/VM).
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
