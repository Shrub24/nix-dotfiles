## Context

The repository already manages user services through Home Manager and pins
external OCI references in `policy/oci-images.nix`. Grist is self-contained
for a single user: its standard container persists document data and account
metadata in `/persist` using SQLite. See `proposal.md` for motivation and
`specs/grist-oci-service/spec.md` for the behavioural contract.

## Goals / Non-Goals

**Goals:**

- Run a reproducibly pinned Grist release as a user-owned Podman service.
- Preserve all Grist state without an additional database service.
- Keep the service inaccessible off-host and keep its signing secret out of
  the Nix store.

**Non-Goals:**

- Remote access, a reverse proxy, SSO, multi-user administration, PostgreSQL,
  Redis, backups, or a locally patched image.
- Declaring Grist's mutable application configuration in Nix.

## Decisions

### Direct pinned Podman image

Use the existing direct-pull OCI service pattern with
`docker.io/gristlabs/grist:1.7.17@sha256:0d9bba2c7139e3e9e15839d03544746f7815bbe76e34dc71c9f6eadd0be82a8c`.
It belongs in `policy/oci-images.nix` so Renovate can update the tag and digest
together. A `dockerTools.pullImage` derivation is unnecessary because no image
patch is required.

### Loopback publishing rather than host networking

Run the container with an explicit `127.0.0.1:8484:8484` publish rule. The
existing LiteLLM service uses host networking, but that would honor Grist's
default `0.0.0.0` listener and expose the single-user login model on the LAN.
No proxy is introduced.

### Standard persistent state and SQLite

Mount `~/.local/share/grist` at `/persist`. This is Grist's documented state
location, covering documents, `home.sqlite3`, and session state. SQLite avoids
an unnecessary database daemon; backup policy remains the user's normal home
directory backup policy.

### Explicit identity settings and encrypted session secret

Expose the initial administrator email and single-organization slug as host
configuration, because they define instance identity and cannot be safely
guessed. Render only `GRIST_SESSION_SECRET` from SOPS into a service
environment file. The module configures `GRIST_IN_SERVICE=true`,
`GRIST_FORCE_LOGIN=true`, telemetry off, and automatic version checks off.

### gVisor sandbox validation before enabling it

Grist's gVisor formula sandbox is desirable but has an unverified rootless
Podman compatibility constraint. The module defaults to gVisor while allowing
the host to leave the variable unset. The first deployment validates formula
isolation; if gVisor cannot start, use Grist's built-in sandbox for this
localhost-only, trusted-user deployment rather than adding privileges or a
second container runtime.

## Risks / Trade-offs

- [Grist's default-email login model is not suitable for network exposure] →
  bind loopback only; add a separately designed authenticated proxy before any
  remote access.
- [Grist logs an informational boot key even in service mode] → treat it as
  irrelevant to normal login; do not expose the service or journal to
  untrusted users.
- [Loss of the persistent directory loses all documents and metadata] → back
  up `~/.local/share/grist` with normal user data.
- [gVisor may fail under rootless Podman] → validate at first start; do not
  weaken container isolation or add privileges to make it work.
- [Pinned images do not update automatically] → Renovate proposes reviewed
  tag-and-digest updates.

## Migration Plan

1. Add the encrypted session secret and select the administrator email and
   organization slug in the host configuration.
1. Apply Home Manager; the service creates the state directory, pulls the
   pinned image, and initializes Grist on first start.
1. Confirm `/status` locally and validate the selected formula sandbox.
1. Roll back by disabling the feature and stopping the service; retain
   `~/.local/share/grist` so no workspace data is removed.
