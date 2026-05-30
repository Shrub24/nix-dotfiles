## ADDED Requirements

### Requirement: Build from GitHub source
The derivation SHALL build `@agentmemory/agentmemory` from the GitHub source using `buildNpmPackage`.

- **Source**: `https://github.com/rohitg00/agentmemory`
- **Version**: Latest stable tag (matching iii-engine compatibility)
- **Build**: `npm run build` via `tsdown` (Rust/rolldown bundler, no native build steps required)

#### Scenario: Build succeeds
- **WHEN** the derivation is built
- **THEN** the npm dependencies are fetched, source compiles with tsdown, and config files are copied to dist/

#### Scenario: No postinstall or native addons
- **WHEN** `package.json` is inspected during build
- **THEN** there SHALL be no `postinstall` script, no `node-gyp` dependency, and no native compilation step

### Requirement: iii-engine on PATH
The derivation SHALL wrap the `agentmemory` binary so `iii-engine` is discoverable via PATH when agentmemory spawns it as a child process.

#### Scenario: Engine on PATH
- **WHEN** `agentmemory` starts
- **THEN** it can find `iii` in PATH and launch it as a child process

### Requirement: CLI entry point
The derivation SHALL expose the `agentmemory` CLI as `$out/bin/agentmemory`.

#### Scenario: CLI runs
- **WHEN** `agentmemory --help` is run
- **THEN** it prints usage information

#### Scenario: MCP mode works
- **WHEN** `agentmemory mcp` is run
- **THEN** it starts in MCP stdio mode (no engine needed)

### Requirement: Optional deps omitted
The derivation SHALL NOT require optional dependencies (jieba, onnxruntime, xenova/transformers) at build time. They are runtime-only if enabled.

#### Scenario: Build without optional deps
- **WHEN** the derivation is built
- **THEN** it succeeds without optional dependencies being installed or compiled
