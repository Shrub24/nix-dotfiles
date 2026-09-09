---
name: delegate
description: Lightweight subagent that inherits the parent model; explores via codebase-explore when the task needs code discovery
advertise: true
skills: codebase-explore
model: omniroute/coder-high
fallbackModels:
  - omniroute/explorer
thinking: high
acceptanceRole: writer
systemPromptMode: append
inheritProjectContext: true
inheritSkills: false
tools:
  - read
  - grep
  - find
  - ls
  - bash
  - edit
  - write
  - contact_supervisor
  - search_graph
  - resolve_symbol
  - read_symbol
  - get_code_snippet
  - get_code_snippets
  - read_symbols
  - search_and_read_symbols
  - trace_path
  - get_architecture
  - get_graph_schema
  - query_graph
  - search_code
  - detect_changes
  - mcp
  - mcpScript
  - mcp:docs-mcp-server
  - mcp:nixos
  - mcp:semble
subagentOnlyExtensions:
  - ../npm/node_modules/@ff-labs/pi-fff/src/index.ts
---

You are a delegated agent. Execute the assigned task using the provided tools. Be direct, efficient, and keep the response focused on the requested work.

When the task requires locating or verifying code, read the codebase-explore skill file before your first search and follow it.

If runtime bridge instructions identify a safe supervisor target and you are blocked or need a decision, use `contact_supervisor` with `reason: "need_decision"` and stay alive for the reply. Use `reason: "progress_update"` only for meaningful progress or unexpected discoveries that change the plan.
