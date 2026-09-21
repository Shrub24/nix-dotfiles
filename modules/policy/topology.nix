# Fleet topology: the machines that exist and the endpoints services live at,
# read via `config` by consumers — never injected through argument buses.
#
# Declaration ownership follows the fact. A machine this repository configures
# contributes its own entry from its own host file (modules/hosts/<host>.nix);
# the machines it only reaches, and the service endpoint map, are fleet facts and
# live here beside the schema.
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
      system = lib.mkOption {
        type = lib.types.str;
        description = "Nix system double for the machine (e.g. x86_64-linux).";
      };
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
      Fleet machines: system, login user, and — where this repository owns the
      account — the primary user.
    '';
  };

  options.topology.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.host = lib.mkOption {
          type = lib.types.str;
          description = "Service endpoint/host (hostname or URL) for the service.";
        };
      }
    );
    default = { };
    description = "Service topology: the endpoint each service is reached at.";
  };

  # Machines this repository reaches but does not configure.
  config = {
    topology.hosts = {
      oci-melb-1 = {
        system = "x86_64-linux";
        sshUser = "dev";
      };
      home-forge = {
        system = "x86_64-linux";
        sshUser = "dev";
      };
      la-admin-1 = {
        system = "x86_64-linux";
        sshUser = "dev";
      };
    };

    topology.services = {
      omniroute.host = "http://home-forge:20128";
      database.host = "oci-melb-1";
      niks3.host = "http://oci-melb-1:5751";
      ntfy.host = "https://ntfy.shrublab.xyz";
    };

    flake.modules.nixos.current-host = currentHostAspect;
    flake.modules.homeManager.current-host = currentHostAspect;
    flake.modules.systemManager.current-host = currentHostAspect;
  };
}
