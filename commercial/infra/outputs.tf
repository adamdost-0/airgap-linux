output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.main.id
}

output "aptly_vm_id" {
  description = "Aptly VM resource ID"
  value       = azurerm_linux_virtual_machine.aptly.id
}

output "aptly_vm_private_ip" {
  description = "Aptly VM private IP address"
  value       = azurerm_network_interface.aptly.private_ip_address
}

output "aptly_identity_principal_id" {
  description = "Principal ID of Aptly managed identity"
  value       = azurerm_user_assigned_identity.aptly.principal_id
}

output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "storage_account_id" {
  description = "Storage account resource ID (if enabled)"
  value       = var.enable_blob_storage ? azurerm_storage_account.aptly[0].id : null
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint (if enabled)"
  value       = var.enable_blob_storage ? azurerm_storage_account.aptly[0].primary_blob_endpoint : null
}

output "storage_container_name" {
  description = "Blob container name for the Aptly pool (if enabled)"
  value       = var.enable_blob_storage ? azurerm_storage_container.aptly_pool[0].name : null
}

output "storage_container_resource_manager_id" {
  description = "ARM resource ID for the Aptly pool blob container (if enabled)"
  value       = var.enable_blob_storage ? azurerm_storage_container.aptly_pool[0].resource_manager_id : null
}

output "storage_cmk_key_id" {
  description = "Key Vault key ID used for storage CMK encryption (if enabled)"
  value       = var.enable_blob_storage && var.enable_customer_managed_keys ? azurerm_key_vault_key.storage_cmk[0].id : null
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (if enabled)"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].id : null
}

output "log_analytics_workspace_workspace_id" {
  description = "Log Analytics workspace ID for queries (if enabled)"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].workspace_id : null
}
