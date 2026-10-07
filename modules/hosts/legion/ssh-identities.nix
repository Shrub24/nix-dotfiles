_:
let
  sopsFile = ../../../secrets/hosts/legion/ssh.yaml;
  systemIdentity = {
    sops = {
      # The externally provisioned age key bootstraps the SSH keys, not vice versa.
      age.sshKeyPaths = [ ];
      gnupg.sshKeyPaths = [ ];
      secrets.ssh-builder = {
        inherit sopsFile;
        key = "builder";
        mode = "0400";
        restartUnits = [ "nix-daemon.service" ];
      };
    };
  };
in
{
  flake.modules = {
    homeManager.legion-ssh-identities = { config, ... }: {
      sops.secrets = {
        ssh-client-ed25519 = {
          inherit sopsFile;
          key = "client/ed25519";
          path = "${config.home.homeDirectory}/.ssh/id_ed25519";
          mode = "0600";
        };
        ssh-client-rsa = {
          inherit sopsFile;
          key = "client/rsa";
          path = "${config.home.homeDirectory}/.ssh/id_rsa";
          mode = "0600";
        };
      };
    };
    nixos.legion-ssh-identities = { config, ... }: {
      imports = [ systemIdentity ];
      sops.secrets = {
        ssh-host-ed25519 = {
          inherit sopsFile;
          key = "host/ed25519";
          mode = "0400";
          restartUnits = [ "sshd.service" ];
        };
        ssh-host-rsa = {
          inherit sopsFile;
          key = "host/rsa";
          mode = "0400";
          restartUnits = [ "sshd.service" ];
        };
        ssh-host-ecdsa = {
          inherit sopsFile;
          key = "host/ecdsa";
          mode = "0400";
          restartUnits = [ "sshd.service" ];
        };
      };
      services.openssh = {
        generateHostKeys = false;
        hostKeys = [
          {
            type = "ed25519";
            path = config.sops.secrets.ssh-host-ed25519.path;
          }
          {
            type = "rsa";
            path = config.sops.secrets.ssh-host-rsa.path;
          }
          {
            type = "ecdsa";
            path = config.sops.secrets.ssh-host-ecdsa.path;
          }
        ];
      };
    };
  };
}
