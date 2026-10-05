{ inputs, lib, ... }:
let
  # Which fleet hosts this machine trusts is host policy, injected per class — an
  # aspect cannot see the flake's `config.fleet`; the contract owns the account.
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

        # One alias per fleet host, carrying that machine's own reach account.
        # Host keys go in the system known-hosts file — Home Manager has no option.
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
      # nix-fleet owns the server hardening. Client tuning stays off: Home Manager
      # owns the client config and the fleet fragment would duplicate its ControlPath.
      imports = [
        inputs.nix-fleet.modules.nixos.ssh
        sshTrustAspect
      ];

      services.ssh-baseline.clientTuning = false;

      # Host keys from the canonical inventory; the system file, not client tuning.
      programs.ssh.knownHosts = resolve.knownHosts config.sshTrust;

      # Client-side host list; the user's own config lives in the homeManager aspect.
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
