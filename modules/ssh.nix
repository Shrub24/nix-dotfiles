{ inputs, lib, ... }:
let
  # Fleet hosts this machine trusts and talks to. Which ones is host policy, so
  # the selection is resolved from the canonical inventory at the composition
  # boundary and injected per class — an aspect cannot see the flake's
  # `config.fleet`. The contract owns the management account
  # (`managementUser`), so no aspect restates it.
  sshTrustAspect = {
    options.sshTrust = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Fleet host specs this machine talks to, from the canonical inventory.";
    };
  };

  resolve = inputs.nix-fleet.lib.buildProfile;
in
{
  flake.modules.homeManager.ssh =
    {
      config,
      ...
    }:
    {
      imports = [ sshTrustAspect ];

      systemd.user.tmpfiles.rules = [
        "d %h/.ssh/ctl 0700 - - -"
      ];

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        settings = {
          # ── Global defaults (Interactive / Latency Baseline) ──────────
          "*" = {
            ServerAliveInterval = 60;
            ServerAliveCountMax = 3;
            ClearAllForwardings = "yes";
            Compression = "yes";
            HashKnownHosts = "yes";
            TCPKeepAlive = "no";
            VisualHostKey = "yes";

            ControlPath = "~/.ssh/ctl/%r@%h:%p";
            ControlPersist = "600";
          };

          "Host ${lib.concatStringsSep " " (builtins.attrNames config.currentHost.peers)}" = {
            ControlMaster = "auto";
            ControlPersist = "600";
            ServerAliveInterval = 60;
            ServerAliveCountMax = 3;
            TCPKeepAlive = "no";
            Compression = "no";
          };

          "Host github.com gitlab.com" = {
            User = "git";
            IdentityFile = "~/.ssh/id_ed25519";
          };
        };

        # One alias per fleet host this machine talks to, carrying that
        # machine's own reach account. Host keys are pinned through the system
        # known-hosts file — Home Manager has no option for it.
        extraConfig = resolve.sshConfig config.sshTrust;
      };
    }

  ;

  flake.modules.systemManager.ssh =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ sshTrustAspect ];

      # Compatibility: sops-nix's host-key change (d855d669, 2026-09-24) reads
      # services.openssh.generateHostKeys whenever services.openssh.enable is
      # false. system-manager's openssh port declares hostKeys but not that
      # one option, so the attribute is missing exactly on our path — sshd
      # isn't system-manager's to run, so enable is false here. False is the
      # honest value and inert besides: sops.age.keyFile is the age key we
      # actually use.
      options.services.openssh.generateHostKeys = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether OpenSSH should generate missing host keys. Declared here because system-manager's openssh port omits it and sops-nix reads it.";
      };

      config = {
        environment.etc."ssh/ssh_known_hosts" = {
          text = resolve.knownHostsText config.sshTrust;
          mode = "0644";
        };

        environment.etc."ssh/ssh_config.d/30-remote-hosts.conf" = {
          text = ''
            # Remote build/managed hosts — ControlMaster enabled for multiplexing
            Host ${lib.concatStringsSep " " (builtins.attrNames config.currentHost.peers)}
              ControlMaster auto
              ControlPersist 600
              ControlPath /run/ssh-%r@%h:%p
              ServerAliveInterval 60
              ServerAliveCountMax 3
              TCPKeepAlive no
              Compression no
              
          '';
          mode = "0644";
        };
      };
    }

  ;

  flake.modules.nixos.ssh =
    {
      config,
      lib,
      ...
    }:
    {
      # nix-fleet owns the server hardening. Client tuning stays off: Home
      # Manager owns the client config, and the fleet fragment's ControlPath
      # would duplicate the one set there.
      imports = [
        inputs.nix-fleet.modules.nixos.ssh
        sshTrustAspect
      ];

      services.ssh-baseline.clientTuning = false;

      # Host keys from the canonical inventory. This is the system file
      # (/etc/ssh/ssh_known_hosts), not client tuning — that stays off because
      # Home Manager owns the user's own config.
      programs.ssh.knownHosts = resolve.knownHosts config.sshTrust;

      # Client-side host list; the server is services.openssh above, user-side
      # client config lives in homeManager.ssh.
      environment.etc."ssh/ssh_config.d/30-remote-hosts.conf" = {
        text = ''
          # Remote build/managed hosts — ControlMaster enabled for multiplexing
          Host ${lib.concatStringsSep " " (builtins.attrNames config.currentHost.peers)}
            ControlMaster auto
            ControlPersist 600
            ControlPath /run/ssh-%r@%h:%p
            ServerAliveInterval 60
            ServerAliveCountMax 3
            TCPKeepAlive no
            Compression no
            
        '';
        mode = "0644";
      };

    }

  ;
}
