## ADDED Requirements

### Requirement: Module option structure
The HM module SHALL define `programs.agentmemory` with typed options:
- `enable` — boolean flag
- `package` — the agentmemory package (default: from pkgs)
- `enginePackage` — the iii-engine package (default: from pkgs)
- `enableGateway` — whether to run the systemd user service (default: true)
- `settings` — freeform attrs for daemon configuration
- `environment` — attrset of env vars to inject
- `environmentFile` — optional path to env file for secrets

#### Scenario: Module registered
- **WHEN** `programs.agentmemory.enable = true` is set in host config
- **THEN** the module activates all configured behaviors

### Requirement: Systemd user service
The module SHALL configure a `systemd.user.services.agentmemory` unit when enabled:
- Type: simple
- ExecStart: `${agentmemory}/bin/agentmemory` (points at wrapped binary)
- Restart: on-failure
- RestartSec: 5s
- Environment: from `programs.agentmemory.environment`
- EnvironmentFile: from `programs.agentmemory.environmentFile`

#### Scenario: Service starts
- **WHEN** systemd starts the agentmemory service
- **THEN** agentmemory launches and begins listening on REST port 3111

#### Scenario: Service restarts on failure
- **WHEN** agentmemory exits with non-zero status
- **THEN** systemd restarts it after 5s

### Requirement: State directory
The module SHALL ensure `~/.agentmemory/` exists and is writable as the agentmemory state directory. This is the default `AGENTMEMORY_EXPORT_ROOT`.

#### Scenario: State dir created on activation
- **WHEN** the service starts for the first time
- **THEN** `~/.agentmemory/` exists with user ownership

### Requirement: Port binding
The module SHALL bind agentmemory ports to 127.0.0.1 only:
- REST API: port 3111
- Viewer UI: port 3113

#### Scenario: Ports bind to localhost
- **WHEN** the service is running
- **THEN** ports 3111 and 3113 listen on 127.0.0.1 only (not 0.0.0.0)

### Requirement: Settings as env vars
The `programs.agentmemory.settings` option SHALL translate configured values into environment variables using the convention `AGENTMEMORY_<KEY>` (uppercased, underscored).

#### Scenario: Settings become env vars
- **WHEN** `settings = { injectContext = true; }` is configured
- **THEN** the service runs with `AGENTMEMORY_INJECT_CONTEXT=true` set

#### Scenario: Port override
- **WHEN** `settings = { restPort = 3115; }` is configured
- **THEN** the service runs with `III_REST_PORT=3115` set
