## ADDED Requirements

### Requirement: MCP server config in Hermes
The change SHALL add an MCP server entry to Hermes configuration pointing at agentmemory's REST API.

- **Type**: HTTP MCP (stdio is also possible but REST avoids a separate process)
- **URL**: `http://localhost:3111/mcp`
- **Key**: `agentmemory`

#### Scenario: Hermes has agentmemory MCP
- **WHEN** Hermes starts with `mcpServers.agentmemory` configured
- **THEN** Hermes can call agentmemory's 51 memory tools (memory_save, memory_recall, memory_smart_search, etc.)

### Requirement: Optional hook scripts
The module SHALL make agentmemory's Hermes integration hooks available at `~/.hermes/hooks/` if explicitly enabled.

- **Source**: Upstream `integrations/hermes/` directory
- **Content**: JS hook scripts that capture tool calls as observations

#### Scenario: Hooks installed when enabled
- **WHEN** hermes-integration hooks are enabled
- **THEN** JS hook scripts are copied to `~/.hermes/hooks/`

### Requirement: No build-time dependency
The Hermes integration SHALL NOT require rebuilding or repackaging the hermes-agent derivation. It SHALL be purely configuration + optional file deployment.

#### Scenario: Zero-build setup
- **WHEN** agentmemory service is already running
- **THEN** adding the MCP entry to Hermes config takes effect on Hermes restart without any Nix rebuild
