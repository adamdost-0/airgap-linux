# commercial/scripts/

Automation scripts for the commercial (low) side operations.

## Purpose

Shell and Python scripts that automate the monthly cycle on the commercial side:

- `mirror-update.sh` — Update Aptly mirrors from upstream Ubuntu
- `snapshot-create.sh` — Create date-stamped snapshots
- `diff-generate.sh` — Compute snapshot diffs
- `bundle-package.sh` — Collect .debs and generate transfer bundle
- `manifest-generate.py` — Build the JSON transfer manifest

## Conventions

- All scripts are idempotent where possible
- Exit codes: 0 = success, 1 = error, 2 = nothing to do
- Logging to stdout (structured JSON for automation, human-readable for interactive)
