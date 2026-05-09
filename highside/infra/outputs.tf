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

output "aptly_repo_fqdn" {
  description = "Internal FQDN for Aptly repository (for APT clients)"
  value       = "repo.${azurerm_private_dns_zone.internal.name}"
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

output "internal_load_balancer_ip" {
  description = "Internal load balancer frontend IP (if enabled)"
  value       = var.enable_internal_load_balancer ? azurerm_lb.internal[0].frontend_ip_configuration[0].private_ip_address : null
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (if enabled)"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].id : null
}

output "log_analytics_workspace_workspace_id" {
  description = "Log Analytics workspace ID for queries (if enabled)"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.main[0].workspace_id : null
}
