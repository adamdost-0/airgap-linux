---
name: "model-selection-governance"
description: "Maintaining squad agent model-selection policy and templates"
domain: "agent-governance"
confidence: "medium"
source: "observed"
---

## Context

Use when changing squad agent model policy in `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, or `.squad/agents/*/charter.md`.

## Patterns

- Keep active governance and templates in sync; update both the runtime agent file and squad template together.
- Preserve charter `Preferred: auto` sections unless a charter explicitly names a deprecated or prohibited model.
- Treat fast/cheap, standard code, and premium/reviewer coordination as separate tiers; only change the tier requested.
- After updates, search active guidance paths for removed model names and leave historical logs untouched.

## Examples

- Fast/cheap non-code and mechanical work: `gpt-5.4-mini`.
- Premium architecture, reviewer gates, security, and multi-agent coordination: `gpt-5.5`.
- Standard code defaults remain unchanged unless directly requested.

## Anti-Patterns

- Do not edit old append-only orchestration/session logs solely to remove historical model mentions.
- Do not rename agents or rewrite unrelated charter content during model policy updates.
