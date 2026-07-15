---
children_hash: 563083a64489bad2364291a6105239b20ae35ab71e91a03d07bc6746532ce2c8
compression_ratio: 0.9976415094339622
condensation_order: 0
covers: [ssh_client_specification.md]
covers_token_total: 424
summary_level: d0
token_count: 423
type: summary
---
## ssh_client_specification.md
---
title: SSH Client Specification
summary: 'SSH client: declarative config via programs.ssh.* at modules/home/remote/ssh.nix, populating ~/.ssh/config, with explicit prohibition on secret management'
tags: []
related: []
keywords: []
createdAt: '2026-07-15T21:17:57.408Z'
updatedAt: '2026-07-15T21:17:57.408Z'
---
## Reason
Document SSH client declarative config spec

## Raw Concept
**Task:**
Declarative SSH client configuration through Home Manager module

**Changes:**
- Added SSH client module at modules/home/remote/ssh.nix

**Files:**
- modules/home/remote/ssh.nix
- modules/home/remote/default.nix

**Flow:**
programs.ssh.enable=true -> module generates ~/.ssh/config

**Timestamp:** 2026-07-15

**Author:** tmux-ssh-mutagen-modules change

## Narrative
### Structure
Two requirements: (1) Declarative SSH client config with 3 scenarios about enablement, global defaults, and host-specific blocks, (2) No secret management with 3 scenarios confirming no known_hosts, authorized_keys, or private key manipulation.

### Dependencies
Uses Home Manager programs.ssh module. Host-specific blocks defined in hosts/arch/home.nix. Secrets managed externally (e.g., sops-nix).

### Highlights
Module explicitly SHALL NOT manage known_hosts, authorized_keys, or private key material. IdentityFile paths MAY reference existing user-managed keys. Host config MAY define Host blocks.

### Rules
Rule 1: The system SHALL provide declarative SSH client configuration via programs.ssh.*
Rule 2: The module SHALL be at modules/home/remote/ssh.nix
Rule 3: The module SHALL NOT manage known_hosts, authorized_keys, or priva
[summary compaction; truncated from 424 tokens]