## ADDED Requirements

### Requirement: OpenCode accesses Headroom through the shared stdio MCP bridge

The system SHALL configure OpenCode to launch Headroom's stdio MCP bridge against the enabled local Headroom proxy.

#### Scenario: OpenCode starts with Headroom enabled

- **WHEN** Home Manager renders the OpenCode configuration while Headroom is enabled
- **THEN** OpenCode SHALL launch `headroom mcp serve` with the local proxy URL
- **AND** OpenCode SHALL be able to discover Headroom compression, retrieval, and statistics tools

#### Scenario: OpenCode starts with Headroom disabled

- **WHEN** Home Manager renders the OpenCode configuration while Headroom is disabled
- **THEN** OpenCode SHALL omit the Headroom MCP server
