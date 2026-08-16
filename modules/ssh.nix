_: {
  flake.modules.homeManager.ssh =
    {
      lib,
      hostFacts,
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
            IPQoS = "lowdelay";

            ControlPath = "~/.ssh/ctl/%r@%h:%p";
            ControlPersist = "600";
          };

          "eu.nixbuild.net" = {
            ControlMaster = "auto";
            StrictHostKeyChecking = "accept-new";
          };

          "Host ${lib.concatStringsSep " " hostFacts.remoteHosts}" = {
            User = "dev";
            ControlMaster = "auto";
          };

          "Host github.com gitlab.com" = {
            User = "git";
            IdentityFile = "~/.ssh/id_ed25519";
            ControlMaster = "auto";
            IPQoS = "throughput";
          };
        };
      };
    }

  ;

  flake.modules.systemManager.ssh =
    {
      lib,
      hostFacts,
      ...
    }:
    {
      environment.etc."ssh/ssh_config.d/30-remote-hosts.conf" = {
        text = ''
          # Remote build/managed hosts — ControlMaster enabled for multiplexing
          Host ${lib.concatStringsSep " " hostFacts.remoteHosts}
            ControlMaster auto
            ControlPersist 600
            ControlPath /run/ssh-%r@%h:%p
            ServerAliveInterval 60
            ServerAliveCountMax 3
            StrictHostKeyChecking accept-new
            TCPKeepAlive no
            Compression no
            IPQoS throughput
            
        '';
        mode = "0644";
      };
    }

  ;
}
