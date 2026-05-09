---
name: "project-structure-docs"
description: "Maintaining canonical repository maps and source-controlled architecture diagrams"
domain: "documentation"
confidence: "medium"
source: "observed"
---

## Context

Use when documenting or reviewing repository structure, directory ownership, or
package/data-flow diagrams in `airgap-linux`.

## Patterns

- Keep `docs/project-structure.md` as the concise canonical directory map.
- Keep the root `README.md` and `docs/README.md` to short pointers only.
- Keep `tests/README.md` as the place that explains validation evidence and what proof to capture.
- Update `docs/diagrams/airgap-package-flow.svg` whenever ownership or flow changes.
- Separate commercial-side upstream references from high-side air-gapped flow language.

## Examples

- Add a new top-level directory: update the structure doc, diagram, and brief README pointers together.
- Rename or move ownership: revise the diagram labels and directory responsibility bullets in the same change.

## Anti-Patterns

- Duplicating the full directory map across multiple READMEs.
- Letting the SVG drift from the written structure map.
- Referencing public internet URLs in high-side documentation.
