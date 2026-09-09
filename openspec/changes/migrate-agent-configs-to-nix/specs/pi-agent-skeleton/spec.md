## REMOVED Requirements

### Requirement: Pi is disabled without runtime residue

**Reason**: Pi is enabled on the Arch host through the native Home Manager
module and carries a full declarative configuration. A requirement asserting
that it stays disabled describes the opposite of the capability's behaviour.

**Migration**: Superseded by "Pi is enabled for the Arch host". The
"skeleton" retention model is dropped entirely; no disabled-state guarantee
survives.

## MODIFIED Requirements

### Requirement: Pi package and settings are declarative

The Pi integration SHALL enable Pi through the native Home Manager
`programs.pi-coding-agent` module with the package supplied by
`inputs.llm-agents`, and SHALL render `settings.json` from
`programs.pi-coding-agent.settings`. The rendered file SHALL be a read-only
Nix store path. Every absolute path inside the rendered settings SHALL be
derived from `config.home.homeDirectory` rather than written as a literal.
Paths that reference targets outside the home directory SHALL be absolute.

Package installation SHALL NOT depend on Pi writing to its own settings file:
packages declared in the rendered `settings.packages` list SHALL be installed
by Pi at startup when they are missing from the agent's package directory.

#### Scenario: Pi is re-enabled

- **WHEN** a host enables Pi and supplies a package and settings
- **THEN** Home Manager SHALL install the selected package
- **AND** it SHALL render those settings under Pi's managed configuration directory

#### Scenario: Pi is enabled with a rendered settings file

- **WHEN** the Arch Home Manager configuration is applied with Pi enabled
- **THEN** `programs.pi-coding-agent.enable = true` with the package from `inputs.llm-agents`
- **AND** `~/.pi/agent/settings.json` resolves to a read-only Nix store path

#### Scenario: Declared packages install without writing settings

- **WHEN** a package source is added to the rendered `settings.packages` list
- **AND** the configured source is absent from `~/.pi/agent/npm/node_modules`
- **THEN** Pi installs that source into its package directory on the next start
- **AND** the rendered `settings.json` is not modified

#### Scenario: Rendered paths contain no hardcoded home directory

- **WHEN** the rendered `settings.json` is inspected
- **THEN** every path under the agent directory is composed from `config.home.homeDirectory`
- **AND** no path references the repository working tree

### Requirement: Pi does not encode extension-specific schemas

The Pi integration SHALL NOT declare repository-owned option schemas for
permissions, MCP adapters, search backends, subagents, Telegram, or
version-specific extension packages. Configuration values supplied to
upstream Home Manager freeform options SHALL NOT be treated as repository-owned
schemas.

#### Scenario: Upstream Pi extensions change

- **WHEN** a future Pi version changes its extension APIs
- **THEN** the repository SHALL define no option schema requiring migration
- **AND** only the values passed to `programs.pi-coding-agent.settings` SHALL need updating

## ADDED Requirements

### Requirement: Pi is enabled for the Arch host

The Arch host SHALL select the `pi` Home Manager aspect and SHALL enable Pi
through `programs.pi-coding-agent.enable`. No system-manager or NixOS aspect
SHALL be introduced for Pi.

#### Scenario: Host composition enables Pi

- **WHEN** `hmAspects` in `modules/hosts/arch.nix` and `_home.nix` in the host directory are inspected
- **THEN** the `pi` aspect is selected and `programs.pi-coding-agent.enable = true` is set
- **AND** no Pi configuration appears in the system-manager or NixOS aspect lists

### Requirement: Pi extension configuration files are rendered by Nix

Pi configuration surfaces not covered by the upstream Home Manager module
SHALL be rendered declaratively as read-only Nix store paths under the agent
directory. These surfaces are the MCP server registry, the per-extension
settings files, and the extension directories that are not installed as
packages.

#### Scenario: Extension configuration is store-backed

- **WHEN** the Home Manager configuration is applied
- **THEN** the MCP registry file and each per-extension settings file under the agent directory resolve to Nix store paths
- **AND** none of them is a symlink into the repository working tree

### Requirement: Pi subagent definitions are rendered from repository sources

Pi subagent definitions SHALL be stored as Markdown files with YAML
frontmatter in the repository and SHALL be rendered as a read-only Nix store
path at the agent definitions directory inside the Pi agent directory. The
cross-tool agent directory SHALL contain no Pi subagent definitions. Effective
per-agent configuration SHALL come from the rendered frontmatter, and
`subagents.agentOverrides` SHALL NOT be used.

#### Scenario: Definitions are store-backed

- **WHEN** the Home Manager configuration is applied
- **THEN** the agent definitions directory under the Pi agent directory resolves to a read-only Nix store path
- **AND** it contains one definition per configured agent

#### Scenario: The cross-tool agent directory stays clean

- **WHEN** the cross-tool agent directory is inspected
- **THEN** it contains no Pi subagent definition
- **AND** its contents remain limited to what the non-Pi agent tooling owns

#### Scenario: Frontmatter is the effective configuration

- **WHEN** a subagent's effective model, thinking level, and tool set are read after the migration
- **THEN** they match the values declared in that definition's frontmatter
- **AND** no `subagents.agentOverrides` entry contributes to them

### Requirement: Pi runtime state is not Nix-owned

Pi runtime state SHALL remain outside the store and SHALL NOT be managed by
Nix. This covers authentication credentials, the project trust store, session
transcripts, package checkouts, model and MCP caches, and run history.

#### Scenario: Runtime state is writable

- **WHEN** Pi authenticates a provider, trusts a project, or records a session
- **THEN** the write succeeds into a non-store path under the agent directory
- **AND** no Home Manager option owns that path

#### Scenario: Credentials are not committed

- **WHEN** the repository is inspected
- **THEN** no Pi credential or trust-store file is present
- **AND** no Nix expression references one as a source
