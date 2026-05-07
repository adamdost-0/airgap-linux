---
name: "project-conventions"
description: "Core structure, ownership, and validation conventions for airgap-linux"
domain: "project-conventions"
confidence: "medium"
source: "observed"
---

## Context

Use this skill when creating or reviewing repository structure, scripts, IaC, tests, or docs for `airgap-linux`, a cross-domain Aptly repository pipeline for Azure air-gapped environments.

## Patterns

### Contract-first implementation

Create or update shared contracts before parallel implementation:
- `docs/manifest-schema.md` remains the human schema reference.
- `transfer/manifest/schema/manifest-v1.0.0.schema.json` should become the machine-readable schema.
- `tests/fixtures/manifests/` should hold valid and invalid manifests used by all lanes.

### Ownership boundaries

- Cheritto owns Aptly/APT/Linux config and scripts under `commercial/aptly/`, `commercial/scripts/`, `highside/aptly/`, and APT smoke-test behavior.
- Nate owns transfer security under `transfer/manifest/`, `transfer/verify/`, and `transfer/encrypt/`.
- Shiherlis owns Azure IaC under `commercial/infra/` and `highside/infra/`.
- Eady owns `docs/`, diagrams, and README consistency.
- Drucker reviews security/compliance; Ralph/Hanna define test and acceptance expectations; McCauley reviews architecture-impacting choices.

### Validation while tooling is absent

No repo-level build/test/lint commands currently exist. Use narrow validation:
- `bash -n` for shell scripts.
- `python3 -m py_compile` for Python scripts.
- `python3 -m json.tool` for JSON fixtures/schema until a validator exists.
- `terraform fmt -check` / `terraform validate` only when Terraform setup is present and offline-safe.

### Air-gap constraints

High-side code must not reference public internet URLs. Commercial-side upstream Ubuntu URLs are allowed only where explicitly documented for mirror sync. Azure Government resources must use government cloud environments/endpoints, Private Endpoints, Managed Identity, CMK where applicable, and required compliance tags.

## Examples

```text
transfer/manifest/schema/manifest-v1.0.0.schema.json
commercial/scripts/mirror-update.sh
highside/scripts/ingest.sh
highside/infra/terraform/main.tf
```

## Anti-Patterns

- Adding repo-level build/test/lint commands before the implementation stack is known.
- Letting multiple agents edit shared contract files simultaneously.
- Using public endpoints or registries in high-side code/config.
- Hardcoding secrets, service principal passwords, connection strings, or LUKS/GPG key material.
- Using `:latest` image tags or public container registries for air-gapped deployment paths.
