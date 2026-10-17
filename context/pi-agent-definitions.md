# Pi agent definitions

## Pi agent definitions live under the Pi agent directory

**Id:** 40f6c003-0f46-4f0b-b916-8d1124d87970
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

The seven subagent definitions are repository files mounted at `~/.pi/agent/agents`. `~/.agents` is the cross-tool agent directory that `opencode.nix` also symlinks, so Pi-specific personas are not placed there. Extension paths in a definition are written relative to the definition file, which keeps them free of hardcoded home directories. Herdsman passes a definition's `skills` paths to Pi unchanged, so those paths carry `@home@` placeholders that the Home Manager module substitutes at build time. The drift guard reads the skill names back out of those paths.

**Alternatives:** placing the personas in `~/.agents`. Rejected because it is shared with other tools.
**Reason:** Pi-specific personas stay with the Pi agent directory they serve.

## Preload only the skills whose absence would break a role's core work

**Id:** dead85c0-0830-4fe2-918e-a86ea777361b
**Type:** decision
**Status:** active
**Evidence:** confirmed
**Source:** ARCHITECTURE.md Durable Decisions, moved here 2026-10-21

A skill whose absence would break the role's core work is preloaded: its body is inlined into every child request, at the cost of that skill's tokens. Advertising it is not enough, because an advertisement lets the model skip the read. Preloading is set per role:

- worker: `lean-implementation` and `testing-discipline`
- delegate: no preloaded skill; it receives `testing-discipline` as an advertised skill
- reviewer: `review-policy` and `lean-implementation`; it receives `testing-discipline` as an advertised skill
- researcher and evidence-auditor: `evidence-discipline`

Every other skill stays advertised and is read when its work needs it.

**Alternatives:** advertising all skills. Rejected because the model skips a read it has only been told about.
**Reason:** the token cost of inlining is accepted only for skills the role cannot work without.
