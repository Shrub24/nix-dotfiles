<!--
canonical-spec: opencode-snip-integration
status: active
source-change: archive/2026-08-09-migrate-tokf-to-snip
source-spec: openspec/changes/archive/2026-08-09-migrate-tokf-to-snip/specs/opencode-snip-integration/spec.md
-->



## Purpose

Defines the canonical requirements for the opencode snip integration capability.

## Requirements

### Requirement: OpenCode plugin registration
The system SHALL register `opencode-snip` in the managed OpenCode plugin list.

#### Scenario: OpenCode config rendered
- **WHEN** the managed OpenCode configuration is materialized from `apps/opencode/opencode.jsonc`
- **THEN** the plugin list SHALL include `opencode-snip`

### Requirement: snip-backed shell filtering
The OpenCode integration SHALL rely on `snip` being available on PATH for shell command rewriting.

#### Scenario: snip available in environment
- **WHEN** OpenCode runs shell commands in an environment where `snip` is installed through Home Manager
- **THEN** the `opencode-snip` plugin SHALL be able to prefix supported commands with `snip`

### Requirement: Unsupported commands passthrough
The integration SHALL preserve normal command execution for commands that `snip` does not rewrite.

#### Scenario: Command not rewritten
- **WHEN** OpenCode invokes a command that is unsupported or intentionally bypassed by `snip`
- **THEN** command execution SHALL continue without requiring repo-local fallback changes
