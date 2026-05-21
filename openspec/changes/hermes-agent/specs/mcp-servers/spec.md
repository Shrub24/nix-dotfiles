## ADDED Requirements

### Requirement: MCP server stdio transport
The module SHALL support MCP servers using stdio transport (command + args).

#### Scenario: Stdio server
- **WHEN** `services.hermes-agent.mcpServers.filesystem = { command = "npx"; args = ["-y", "@modelcontextprotocol/server-filesystem", "/data/workspace"]; }`
- **THEN** the generated config SHALL include the server with command and args

### Requirement: MCP server HTTP transport
The module SHALL support MCP servers using HTTP/StreamableHTTP transport.

#### Scenario: HTTP server
- **WHEN** `services.hermes-agent.mcpServers.remote-api = { url = "https://mcp.example.com/v1/mcp"; headers = { Authorization = "Bearer ..."; }; }`
- **THEN** the generated config SHALL include the server with url and headers

### Requirement: MCP server OAuth authentication
The module SHALL support OAuth 2.1 PKCE authentication for MCP servers.

#### Scenario: OAuth server
- **WHEN** `services.hermes-agent.mcpServers.my-oauth = { url = "https://mcp.example.com/mcp"; auth = "oauth"; }`
- **THEN** the generated config SHALL include the server with auth = "oauth"

### Requirement: MCP server enable/disable
Each MCP server SHALL support being enabled or disabled independently.

#### Scenario: Disabled server
- **WHEN** `services.hermes-agent.mcpServers.context7 = { enabled = false; ... }`
- **THEN** the generated config SHALL include `enabled: false` for that server

### Requirement: MCP server environment variables
The module SHALL support passing environment variables to MCP servers.

#### Scenario: Server with env vars
- **WHEN** `services.hermes-agent.mcpServers.github = { command = "npx"; args = [...]; env = { GITHUB_TOKEN = "${GITHUB_TOKEN}"; }; }`
- **THEN** the generated config SHALL include the environment variables for that server

### Requirement: MCP server tool filtering
The module SHALL support filtering which tools are exposed by each MCP server.

#### Scenario: Tool allowlist
- **WHEN** `services.hermes-agent.mcpServers.context7.tools = { include = ["search", "query"]; }`
- **THEN** the generated config SHALL include the tool filter for that server

### Requirement: MCP server sampling configuration
The module SHALL support configuring server-initiated LLM requests (sampling).

#### Scenario: Sampling config
- **WHEN** `services.hermes-agent.mcpServers.my-server.sampling = { enabled = true; model = "gpt-4o"; max_tokens_cap = 4096; }`
- **THEN** the generated config SHALL include the sampling configuration

### Requirement: Pre-configured MCP server set
The system SHALL configure commonly used MCP servers: context7, desktop-commander, jina-reader, github, semgrep, nixos, markdownify.

#### Scenario: Default MCP servers
- **WHEN** the hermes module is enabled with default MCP config
- **THEN** the generated config SHALL include context7, desktop-commander, jina-reader, github, semgrep, nixos, and markdownify servers
