## ADDED Requirements

### Requirement: OpenCode accesses Headroom's shared MCP endpoint
The system SHALL configure OpenCode to use the enabled local Headroom proxy as a remote MCP server.

#### Scenario: OpenCode starts with Headroom enabled
- **WHEN** Home Manager renders the OpenCode configuration while Headroom is enabled
- **THEN** OpenCode SHALL register the local Headroom `/mcp` endpoint as an enabled remote MCP server
- **AND** OpenCode SHALL be able to discover Headroom compression, retrieval, and statistics tools

#### Scenario: OpenCode starts with Headroom disabled
- **WHEN** Home Manager renders the OpenCode configuration while Headroom is disabled
- **THEN** OpenCode SHALL omit the Headroom remote MCP server
