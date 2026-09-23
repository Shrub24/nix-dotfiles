{ inputs, lib, ... }:
let
  # Fleet hosts this machine trusts and talks to. Which ones is host policy, so
  # the selection is resolved from the canonical inventory at the composition
  # boundary and injected per class — an aspect cannot see the flake's
  # `config.fleet`. The contract owns the login user (`ssh.user`), so no aspect
  # restates it.
  sshTrustAspect = {
    options.sshTrust = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Fleet host specs this machine talks to, from the canonical inventory.";
    };
  };

  resolve = inputs.nix-fleet.lib.buildProfile;

  # The contract publishes host keys in option form (NixOS'
  # `programs.ssh.knownHosts`); system-manager has no such option, so the
  # system file is rendered here — the same gap `machinesFile` fills for build
  # machines, still open for host keys.
  knownHostsFile =
    specs:
    lib.concatLines (
      lib.mapAttrsToList (_: entry: "${lib.concatStringsSep "," entry.hostNames} ${entry.publicKey}") (
        resolve.knownHosts specs
      )
    );
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
            StrictHostKeyChecking = "accept-new";
            VisualHostKey = "yes";

            ControlMaster = "auto";
            ControlPath = "~/.ssh/ctl/%r@%h:%p";
            ControlPersist = "600";
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

      environment.etc."ssh/ssh_known_hosts" = {
        text = knownHostsFile config.sshTrust;
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
            StrictHostKeyChecking accept-new
            TCPKeepAlive no
            Compression no
            
        '';
        mode = "0644";
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

      services.ssh-baseline = {
        enable = true;
        clientTuning = false;
      };

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
            StrictHostKeyChecking accept-new
            TCPKeepAlive no
            Compression no
            
        '';
        mode = "0644";
      };

    }

  ;
}
