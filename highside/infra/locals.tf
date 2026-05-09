locals {
  # Naming prefix following Azure CAF conventions
  name_prefix = "aptly-gov-${var.environment}"
  
  # Common tags applied to all resources
  common_tags = {
    Environment    = var.environment
    Project        = "airgap-linux"
    Owner          = var.owner
    Classification = var.classification
    Compliance     = var.compliance
    ManagedBy      = "terraform"
    Component      = "highside-air-gapped"
  }

  # Resource-specific naming
  resource_group_name      = "${local.name_prefix}-rg"
  vnet_name                = "${local.name_prefix}-vnet"
  aptly_subnet_name        = "${local.name_prefix}-aptly-subnet"
  privatelink_subnet_name  = "${local.name_prefix}-privatelink-subnet"
  nsg_aptly_name           = "${local.name_prefix}-aptly-nsg"
  vm_name                  = "${local.name_prefix}-vm"
  storage_account_name     = "aptlygov${var.environment}${random_string.storage_suffix.result}"
  key_vault_name           = "${local.name_prefix}-kv-${random_string.kv_suffix.result}"
  ilb_name                 = "${local.name_prefix}-ilb"
  
  # Managed identity for Aptly VM
  aptly_identity_name = "${local.name_prefix}-aptly-id"

  # DNS zone name for internal repo access
  internal_dns_zone_name = var.internal_dns_suffix

  # Azure Government cloud endpoint suffix mapping
  endpoint_suffixes = {
    usgovernment         = "usgovcloudapi.net"
    usgovernmentsecret   = "microsoftazure.us"
    usgovernmenttopsecret = "microsoftazure.eaglex.ic.gov"
  }
  
  current_endpoint_suffix = local.endpoint_suffixes[var.azure_government_environment]

  # Log Analytics workspace naming
  log_analytics_workspace_name = "${local.name_prefix}-law"

  # Diagnostic settings categories for Key Vault
  keyvault_audit_logs = [
    "AuditEvent",
    "AzurePolicyEvaluationDetails"
  ]

  # Diagnostic settings categories for Storage Account
  storage_audit_logs = [
    "StorageRead",
    "StorageWrite",
    "StorageDelete"
  ]

  # Diagnostic settings categories for NSG (flow logs)
  nsg_audit_logs = [
    "NetworkSecurityGroupEvent",
    "NetworkSecurityGroupRuleCounter"
  ]

  # Diagnostic settings categories for Private Endpoints and Private DNS zones
  privatelink_audit_logs = [
    "PrivateEndpointNetworkPolicies"
  ]
}
