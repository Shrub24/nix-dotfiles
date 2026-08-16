## 1. Configuration inputs

- [x] 1.1 Pin the Grist OCI image in `policy/oci-images.nix` and add its loopback service metadata to `lib/web-services.nix`.

  - refs: `policy/oci-images.nix`, `lib/web-services.nix`
  - criteria: The image reference has a release tag and immutable digest; the catalog exposes port 8484 and `/status`.
  - verify: `nix eval .#webServices --json`

- [x] 1.2 Add the Grist session secret to user-scoped SOPS configuration and render a service-only environment file.

  - refs: `modules/home/sops.nix`, `secrets/agents.yaml`
  - criteria: Only `GRIST_SESSION_SECRET` is rendered; its value is absent from the Nix store, generated unit definition, and repository plaintext files.
  - verify: Inspect the evaluated service configuration and rendered-template declaration.

## 2. Home Manager service

- [x] 2.1 Implement the Grist Home Manager module using the existing direct-pull OCI service pattern.

  - refs: `modules/home/agents/litellm/default.nix`, `policy/oci-images.nix`
  - criteria: The module creates the persistent state directory, runs the pinned image with `/persist` mounted, publishes only `127.0.0.1:8484`, restarts after secret/config changes, and supports a gVisor-to-built-in-sandbox fallback without extra privileges.
  - delegate: CoderAgent
  - verify: `nix flake check --no-build --no-write-lock-file`

- [x] 2.2 Register the module and enable it for `arch` with the selected administrator email and single-organization slug.

  - refs: `flake-modules/agents/services.nix`, `hosts/arch/home.nix`
  - depends: 2.1
  - criteria: The feature remains host-selected and evaluation rejects missing identity settings when enabled.
  - verify: `nix flake check --no-build --no-write-lock-file`

## 3. Documentation and deployment verification

- [x] 3.1 Document Grist in the web-service catalog and architecture service inventory, including its localhost-only access boundary and persistent data location.

  - refs: `docs/web-services-catalog.md`, `ARCHITECTURE.md`
  - delegate: DocWriter
  - verify: `nix flake check --no-build --no-write-lock-file`

- [x] 3.2 Apply the configuration and verify first-start behavior locally.

  - criteria: `http://127.0.0.1:8484/status` returns success, Grist state survives a restart, and the gVisor formula-isolation check either passes or the documented built-in-sandbox fallback is selected.
  - verify: `systemctl --user status grist.service` and `curl --fail http://127.0.0.1:8484/status`

- [x] 3.3 Run final static validation and review the change against its specification.

  - verify: `nix fmt`, `nix flake check --no-build --no-write-lock-file`, and `openspec validate add-grist-oci-service --strict`
