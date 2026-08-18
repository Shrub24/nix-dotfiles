# Shared typed top-level data (SKILL.md "Shared typed top-level data"):
# host/service topology owned by its domain, read via `config` by feature
# modules — never injected through argument buses. Populated only at the host
# composition layer (modules/hosts/arch.nix).
{ lib, ... }:
{
  options.topology.hosts = lib.mkOption {
    type = with lib.types; attrsOf (submodule {
      options = {
        system = lib.mkOption {
          type = lib.types.str;
          description = "Nix system double for the host (e.g. x86_64-linux).";
        };
        primaryUser = lib.mkOption {
          type = lib.types.str;
          description = "Primary user account name on the host.";
        };
        remoteHosts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Remote build/managed hosts reachable from this host.";
        };
      };
    });
    default = { };
    description = "Host topology: per-host system, primary user and remote hosts.";
  };

  options.topology.services = lib.mkOption {
    type = with lib.types; attrsOf (submodule {
      options.host = lib.mkOption {
        type = lib.types.str;
        description = "Service endpoint/host (hostname or URL) for the service.";
      };
    });
    default = { };
    description = "Service topology: the endpoint each service is reached at.";
  };
}
