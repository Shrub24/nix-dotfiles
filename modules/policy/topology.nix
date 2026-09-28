# Fleet topology: the machines that exist, read via `config` by consumers —
# never injected through argument buses. Service endpoints are deliberately not
# restated here: consumers resolve them from nix-fleet's canonical service
# inventory (`lib.serviceEndpoints`), so the two can never disagree.
#
# Declaration ownership follows the fact. A machine this repository configures
# contributes its own entry from its own host file (modules/hosts/<host>.nix);
# the machines it only reaches are fleet facts and live here beside the schema.
{ lib, ... }:
let
  primaryUserType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Primary user account name on the machine.";
      };
      uid = lib.mkOption {
        type = lib.types.int;
        description = "Primary user account numeric UID.";
      };
      gid = lib.mkOption {
        type = lib.types.int;
        description = "Primary user account numeric GID.";
      };
    };
  };

  machineType = lib.types.submodule {
    options = {
      sshUser = lib.mkOption {
        type = lib.types.str;
        description = "Login user used to reach the machine over ssh.";
      };
      primaryUser = lib.mkOption {
        type = lib.types.nullOr primaryUserType;
        default = null;
        description = ''
          Account this repository configures on the machine. Null on machines it
          reaches but does not own.
        '';
      };
    };
  };

  # The per-evaluation projection of the entry a host composition selected. This
  # is what reusable features read; none of them knows which machine it is in.
  currentHostType = lib.types.submodule {
    options = {
      id = lib.mkOption {
        type = lib.types.str;
        description = "Stable machine identity: this machine's key in `topology.hosts`.";
      };
      primaryUser = lib.mkOption {
        type = primaryUserType;
        description = "Account this repository configures on the current machine.";
      };
      peers = lib.mkOption {
        type = lib.types.attrsOf machineType;
        description = ''
          Every other machine in the fleet, including the ones this repository
          does not own. Subtracted at the composition boundary, never in a
          feature.
        '';
      };
    };
  };

  currentHostAspect = {
    options.currentHost = lib.mkOption {
      type = currentHostType;
      description = "Identity of the machine this evaluation is composed for.";
    };
  };
in
{
  options.topology.hosts = lib.mkOption {
    type = lib.types.attrsOf machineType;
    default = { };
    description = ''
      Fleet machines: login user, and — where this repository owns the account
      — the primary user. Identity and target system are canonical facts owned
      by nix-fleet (`config.fleet.hosts.<id>`); only what is ours to decide
      lives here.
    '';
  };

  # Machines this repository reaches but does not configure.
  config = {
    topology.hosts = {
      oci-melb-1.sshUser = "dev";
      home-forge.sshUser = "dev";
      la-admin-1.sshUser = "dev";
    };

    flake.modules.nixos.current-host = currentHostAspect;
    flake.modules.homeManager.current-host = currentHostAspect;
    flake.modules.systemManager.current-host = currentHostAspect;
  };
}
