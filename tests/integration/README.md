# tests/integration/

Integration validation evidence for end-to-end repository pipeline work.

Keep evidence here when it proves cross-component behavior, such as Bicep
infrastructure readiness, low-side Aptly snapshot export, transfer verification,
or high-side repo hydration. Do not create milestone-only evidence files when an
existing category can carry the proof; add the milestone ID to the relevant
section instead.

## Phase 2 evidence index

### P2-M1: Bicep infrastructure baseline

Owned implementation paths:

- `commercial/infra/`
- `highside/infra/`

Repo-backed changes:

- Commercial and high-side infrastructure are Bicep templates, not Terraform.
- Both templates provision an Aptly VM with a local managed data disk for native
  Aptly filesystem storage.
- Both templates include managed identity, private Key Vault access, private DNS,
  NSG rules, and required tags.
- No Azure Blob-backed Aptly pool or blobfuse2 mount is defined.

Validation commands:

```bash
bicep build commercial/infra/main.bicep --stdout >/tmp/commercial-main.json
bicep build highside/infra/main.bicep --stdout >/tmp/highside-main.json
python3 -m json.tool commercial/infra/main.parameters.example.json >/dev/null
python3 -m json.tool highside/infra/main.parameters.example.json >/dev/null
```

Current sandbox result: passed.

### P2-M2: Low-side Aptly snapshot export

Owned implementation paths:

- `commercial/aptly/`
- `commercial/scripts/`
- `transfer/manifest/`

Run in the low-side Phase 2 environment with real Aptly state:

```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export MIRROR_NAME=ubuntu-noble-main
commercial/scripts/mirror-update.sh
export COMPONENT=main
commercial/scripts/snapshot-create.sh
export PREVIOUS_SNAPSHOT=ubuntu-noble-main-20260401
export CURRENT_SNAPSHOT=ubuntu-noble-main-20260501
export OUTPUT_FILE=/var/tmp/diff-20260501.txt
commercial/scripts/diff-generate.sh
```

Current sandbox result: static shell validation passed; live Aptly evidence is
pending a Phase 2 low-side environment with real Aptly state.

### P2-M3: HDD transfer verification

Owned implementation paths:

- `transfer/manifest/`
- `transfer/verify/`
- `transfer/encrypt/`
- `highside/scripts/verify-bundle.sh`

Static validation commands:

```bash
python3 transfer/manifest/validate-manifest.py transfer/manifest/example-manifest.json
find commercial highside transfer -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
git diff --check HEAD
```

Current sandbox result: passed.

### P2-M4: High-side Aptly repo hydration

Owned implementation paths:

- `highside/aptly/`
- `highside/scripts/`

Run in the high-side Phase 2 environment after HDD mount and verification:

```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export REPO_NAME=highside-noble-main
export PACKAGE_DIR=/mnt/airgap-transfer/packages/main
export MANIFEST_FILE=/mnt/airgap-transfer/manifest.json
highside/scripts/import-packages.sh
highside/scripts/remove-packages.sh
export DISTRIBUTION=noble
highside/scripts/publish-update.sh
highside/scripts/reconcile.sh
export APT_REPO_URL=https://repo.apt.internal.local/ubuntu
export COMPONENT=main
highside/scripts/smoke-test.sh
```

Current sandbox result: static shell validation passed; live Aptly/HDD hydration
evidence is pending a Phase 2 high-side environment with mounted transfer media.
