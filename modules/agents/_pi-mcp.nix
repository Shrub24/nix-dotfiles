# The register of MCP servers this repository serves to Pi: each aspect that owns
# a server writes its entry here, and the pi aspect renders the register into
# ~/.pi/agent/mcp.json. Entries Pi owns itself stay in modules/agents/pi.nix.
#
# It is a raw module that every writer imports, so an aspect that serves a server
# never depends on the pi aspect being selected. It declares into Home Manager's
# namespace (there is no repository-owned one yet) so that an upstream option of
# the same name fails the build rather than being silently shadowed.
{
  lib,
  ...
}:
{
  options.programs.pi-coding-agent.mcpServers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "HTTP endpoint, for a server Pi reaches over the network.";
          };

          command = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Executable Pi spawns, for a server it runs itself.";
          };

          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Arguments for `command`.";
          };

          exposure = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.enum [
                "codemode"
                "deferred"
                "direct"
              ]
            );
            default = null;
            description = ''
              How the model reaches this server's tools: `direct` declares them
              like built-ins, `deferred` leaves them to `tool_search`, and
              `codemode` keeps them in scripts. Unset leaves Pi's own default,
              which is `codemode`.
            '';
          };

          description = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              What the server offers, in a sentence. Pi lists it in the system
              prompt for a server reached through codemode or tool search, and
              tool search ranks its tools by it.
            '';
          };

          headers = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = ''
              Request headers for an authenticated `url`. A value may be a Pi
              command form (`!cmd`), which keeps a credential out of the store
              and out of the environment.
            '';
          };
        };
      }
    );
    default = { };
    description = ''
      MCP servers Pi connects to, keyed by the name Pi sees. An HTTP server
      sets `url` (and `headers` where the endpoint authenticates); a stdio
      server sets `command` and `args`. `exposure` and `description` decide how
      the server reaches the model, since Pi declares a server's tools only
      when they are asked for.
    '';
  };
}
