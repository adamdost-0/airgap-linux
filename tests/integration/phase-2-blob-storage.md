# P2-M1 Blob Storage IaC Evidence

Milestone: `P2-M1` from `docs/phase-2-milestones.md`.

## Repo-backed changes

- Commercial and high-side Terraform define an Aptly pool blob container when
  `enable_blob_storage = true`.
- Storage accounts use a user-assigned managed identity and a conditional
  customer-managed Key Vault key when `enable_customer_managed_keys = true`.
- The Aptly managed identity receives blob data access and Key Vault crypto
  service encryption access.
- Outputs expose the pool container name, container ARM ID, blob endpoint, and
  CMK key ID for the next blobfuse2 validation lane.

## Validation commands

Run from the repository root:

```bash
python3 transfer/manifest/validate-manifest.py transfer/manifest/example-manifest.json
find commercial highside transfer -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
git diff --check HEAD
for env in commercial highside; do
  grep -q 'resource "azurerm_storage_container" "aptly_pool"' "$env/infra/main.tf"
  grep -q 'resource "azurerm_key_vault_key" "storage_cmk"' "$env/infra/main.tf"
  grep -q 'customer_managed_key' "$env/infra/main.tf"
  grep -q 'output "storage_container_name"' "$env/infra/outputs.tf"
done
terraform -chdir=commercial/infra fmt -check
terraform -chdir=commercial/infra validate
terraform -chdir=highside/infra fmt -check
terraform -chdir=highside/infra validate
```

## Current sandbox result

- Manifest validation: passed.
- Shell syntax validation: passed.
- Whitespace validation: passed.
- Terraform resource contract grep checks: passed.
- Terraform validation: blocked in this sandbox because the `terraform` binary
  is not installed. Re-run the Terraform commands above in the Phase 2
  infrastructure environment before accepting live deployment.
