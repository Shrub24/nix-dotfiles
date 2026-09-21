_: {
  flake.modules.homeManager.ssh =
    {
      config,
      lib,
      ...
    }:
    {
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

            ControlPath = "~/.ssh/ctl/%r@%h:%p";
            ControlPersist = "600";
          };

          "eu.nixbuild.net" = {
            ControlMaster = "auto";
            StrictHostKeyChecking = "accept-new";
          };

          "Host github.com gitlab.com" = {
            User = "git";
            IdentityFile = "~/.ssh/id_ed25519";
            ControlMaster = "auto";
          };
        }
        # One alias per peer carrying that machine's own login user: machines this
        # repository owns authenticate as their own account, the build and admin
        # boxes as theirs.
        // lib.mapAttrs' (
          name: peer:
          lib.nameValuePair "Host ${name}" {
            User = peer.sshUser;
            ControlMaster = "auto";
          }
        ) config.currentHost.peers;
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
      services.openssh = {
        enable = true;
        openFirewall = true;
        settings.PasswordAuthentication = false;
      };

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
