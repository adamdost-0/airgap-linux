---
name: "milestone-scope-contract"
description: "Define milestone scope with value, in-scope, out-of-scope, and evidence of done"
domain: "planning"
confidence: "medium"
source: "observed"
---

## Context

Use when a milestone needs to be made unambiguous before implementation starts.

## Patterns

- State the value the milestone delivers in one sentence.
- List what is in scope and what is explicitly out of scope.
- Define done in terms of repo-backed evidence, not status prose.
- Block the milestone if there is no canonical source-of-truth for the scope.

## Examples

- M1: repo baseline, contract clarity, and validation evidence.
- Acceptance evidence: structure docs, schema references, fixtures, and reproducible checks.

## Anti-Patterns

- Guessing scope from informal discussion.
- Treating narrative updates as completion evidence.
- Expanding a milestone to include unrelated implementation work.
