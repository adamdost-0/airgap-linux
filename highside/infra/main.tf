#------------------------------------------------------------------------------
# Resource Group
#------------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

#------------------------------------------------------------------------------
# Random Suffixes (for globally unique names)
#------------------------------------------------------------------------------

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

#------------------------------------------------------------------------------
# Networking — VNet, Subnets, NSG
#------------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space
  tags                = local.common_tags
}

resource "azurerm_subnet" "aptly" {
  name                 = local.aptly_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aptly_subnet_address_prefix]
}

resource "azurerm_subnet" "privatelink" {
  name                 = local.privatelink_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.privatelink_subnet_address_prefix]

  # Enable private endpoint support
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_network_security_group" "aptly" {
  name                = local.nsg_aptly_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  # Deny all inbound by default
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTPS from allowed client subnets (for APT clients)
  dynamic "security_rule" {
    for_each = length(var.allowed_client_subnets) > 0 ? [1] : []
    content {
      name                       = "AllowHTTPSFromClients"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefixes    = var.allowed_client_subnets
      destination_address_prefix = "*"
    }
  }

  # Deny all outbound to internet (air-gapped)
  security_rule {
    name                       = "DenyInternetOutbound"
    priority                   = 4095
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Allow outbound to VNet and Azure services via service tags
  security_rule {
    name                       = "AllowVNetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_subnet_network_security_group_association" "aptly" {
  subnet_id                 = azurerm_subnet.aptly.id
  network_security_group_id = azurerm_network_security_group.aptly.id
}

#------------------------------------------------------------------------------
# Managed Identity — User-Assigned for Aptly VM
#------------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "aptly" {
  name                = local.aptly_identity_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

#------------------------------------------------------------------------------
# Key Vault (for GPG public keys, TLS certs, encryption keys)
#------------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  # Disable public network access — use private endpoint only
  public_network_access_enabled = false

  # RBAC mode for access control
  enable_rbac_authorization = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.common_tags
}

# Grant Key Vault Secrets User role to Aptly managed identity
resource "azurerm_role_assignment" "aptly_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aptly.principal_id
}

# Grant Key Vault Crypto User role to Aptly managed identity (for CMK)
resource "azurerm_role_assignment" "aptly_kv_crypto_user" {
  count                = var.enable_customer_managed_keys ? 1 : 0
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_user_assigned_identity.aptly.principal_id
}

resource "azurerm_role_assignment" "aptly_kv_crypto_service_encryption_user" {
  count                = var.enable_blob_storage && var.enable_customer_managed_keys ? 1 : 0
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.aptly.principal_id
}

resource "azurerm_key_vault_key" "storage_cmk" {
  count        = var.enable_blob_storage && var.enable_customer_managed_keys ? 1 : 0
  name         = local.storage_cmk_key_name
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  tags         = local.common_tags
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault" {
  name                = "${local.key_vault_name}-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.privatelink.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "${local.key_vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }
}

resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.${local.current_endpoint_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                  = "${local.vnet_name}-kv-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.main.id
  tags                  = local.common_tags
}

#------------------------------------------------------------------------------
# Storage Account (Phase 2 — Blob storage for Aptly pool)
#------------------------------------------------------------------------------

resource "azurerm_storage_account" "aptly" {
  count                     = var.enable_blob_storage ? 1 : 0
  name                      = local.storage_account_name
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true

  # Disable public network access (air-gapped)
  public_network_access_enabled = false

  # Enable infrastructure encryption
  infrastructure_encryption_enabled = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aptly.id]
  }

  dynamic "customer_managed_key" {
    for_each = var.enable_customer_managed_keys ? [1] : []
    content {
      key_vault_key_id          = azurerm_key_vault_key.storage_cmk[0].id
      user_assigned_identity_id = azurerm_user_assigned_identity.aptly.id
    }
  }

  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = local.common_tags

  depends_on = [
    azurerm_role_assignment.aptly_kv_crypto_service_encryption_user
  ]
}

resource "azurerm_storage_container" "aptly_pool" {
  count                 = var.enable_blob_storage ? 1 : 0
  name                  = var.aptly_pool_container_name
  storage_account_id    = azurerm_storage_account.aptly[0].id
  container_access_type = "private"
}

# Grant Storage Blob Data Contributor to Aptly managed identity
resource "azurerm_role_assignment" "aptly_storage_blob" {
  count                = var.enable_blob_storage ? 1 : 0
  scope                = azurerm_storage_account.aptly[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.aptly.principal_id
}

# Private Endpoint for Blob Storage
resource "azurerm_private_endpoint" "storage_blob" {
  count               = var.enable_blob_storage ? 1 : 0
  name                = "${local.storage_account_name}-blob-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.privatelink.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "${local.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.aptly[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob[0].id]
  }
}

resource "azurerm_private_dns_zone" "storage_blob" {
  count               = var.enable_blob_storage ? 1 : 0
  name                = "privatelink.blob.core.${local.current_endpoint_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  count                 = var.enable_blob_storage ? 1 : 0
  name                  = "${local.vnet_name}-blob-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob[0].name
  virtual_network_id    = azurerm_virtual_network.main.id
  tags                  = local.common_tags
}

#------------------------------------------------------------------------------
# Internal DNS Zone (for APT clients to resolve repo)
#------------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "internal" {
  name                = local.internal_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "internal" {
  name                  = "${local.vnet_name}-internal-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = azurerm_virtual_network.main.id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_a_record" "aptly" {
  name                = "repo"
  zone_name           = azurerm_private_dns_zone.internal.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_network_interface.aptly.private_ip_address]
  tags                = local.common_tags
}

#------------------------------------------------------------------------------
# Aptly VM (Linux VM with Managed Identity)
#------------------------------------------------------------------------------

resource "azurerm_network_interface" "aptly" {
  name                = "${local.vm_name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.aptly.id
    private_ip_address_allocation = "Dynamic"
    # No public IP address
  }
}

resource "azurerm_linux_virtual_machine" "aptly" {
  name                            = local.vm_name
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.aptly_vm_size
  admin_username                  = var.aptly_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.aptly.id]
  tags                            = local.common_tags

  # User-assigned managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aptly.id]
  }

  admin_ssh_key {
    username   = var.aptly_admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    name                 = "${local.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128

    # TODO: Enable customer-managed key when var.enable_customer_managed_keys is true
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # TODO: Add custom_data or cloud-init for Aptly installation and configuration
}

# Additional data disk for Aptly pool (local storage Phase 1)
resource "azurerm_managed_disk" "aptly_data" {
  name                 = "${local.vm_name}-datadisk"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
  tags                 = local.common_tags

  # TODO: Enable customer-managed key when var.enable_customer_managed_keys is true
}

resource "azurerm_virtual_machine_data_disk_attachment" "aptly_data" {
  managed_disk_id    = azurerm_managed_disk.aptly_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.aptly.id
  lun                = 0
  caching            = "ReadWrite"
}

#------------------------------------------------------------------------------
# Internal Load Balancer (optional, for HA)
#------------------------------------------------------------------------------

resource "azurerm_lb" "internal" {
  count               = var.enable_internal_load_balancer ? 1 : 0
  name                = local.ilb_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  tags                = local.common_tags

  frontend_ip_configuration {
    name                          = "internal-frontend"
    subnet_id                     = azurerm_subnet.aptly.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "aptly" {
  count           = var.enable_internal_load_balancer ? 1 : 0
  name            = "${local.ilb_name}-backend"
  loadbalancer_id = azurerm_lb.internal[0].id
}

resource "azurerm_lb_probe" "https" {
  count               = var.enable_internal_load_balancer ? 1 : 0
  name                = "https-probe"
  loadbalancer_id     = azurerm_lb.internal[0].id
  protocol            = "Https"
  port                = 443
  request_path        = "/dists/noble/Release"
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "https" {
  count                          = var.enable_internal_load_balancer ? 1 : 0
  name                           = "https-rule"
  loadbalancer_id                = azurerm_lb.internal[0].id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "internal-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.aptly[0].id]
  probe_id                       = azurerm_lb_probe.https[0].id
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 15
}

#------------------------------------------------------------------------------
# Log Analytics Workspace (for diagnostics and audit logging)
#------------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = local.log_analytics_workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags

  # Air-gapped: No public ingestion or query endpoints
  # TODO: Configure private link for Log Analytics workspace when supported in gov environment
}

#------------------------------------------------------------------------------
# Diagnostic Settings — Key Vault
#------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count                      = var.enable_log_analytics ? 1 : 0
  name                       = "${azurerm_key_vault.main.name}-diag"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  dynamic "enabled_log" {
    for_each = local.keyvault_audit_logs
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

#------------------------------------------------------------------------------
# Diagnostic Settings — Storage Account (if enabled)
#------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  count                      = var.enable_blob_storage && var.enable_log_analytics ? 1 : 0
  name                       = "${azurerm_storage_account.aptly[0].name}-diag"
  target_resource_id         = azurerm_storage_account.aptly[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Storage Blob service diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  count                      = var.enable_blob_storage && var.enable_log_analytics ? 1 : 0
  name                       = "${azurerm_storage_account.aptly[0].name}-blob-diag"
  target_resource_id         = "${azurerm_storage_account.aptly[0].id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  dynamic "enabled_log" {
    for_each = local.storage_audit_logs
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

#------------------------------------------------------------------------------
# Diagnostic Settings — Network Security Group
#------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  count                      = var.enable_log_analytics ? 1 : 0
  name                       = "${azurerm_network_security_group.aptly.name}-diag"
  target_resource_id         = azurerm_network_security_group.aptly.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  dynamic "enabled_log" {
    for_each = local.nsg_audit_logs
    content {
      category = enabled_log.value
    }
  }
}

#------------------------------------------------------------------------------
# Diagnostic Settings — Private Endpoints
#------------------------------------------------------------------------------

# TODO: Add diagnostic settings for Private Endpoints when supported
# Key Vault PE, Storage Blob PE (if enabled)
# Current limitation: Private Endpoint diagnostics may not support all log categories in gov cloud

#------------------------------------------------------------------------------
# VM Diagnostics — System Logs via Azure Monitor Agent
#------------------------------------------------------------------------------

# TODO: Install Azure Monitor Agent extension on Aptly VM when var.enable_vm_diagnostics is true
# Collect syslog, auth logs, package manager logs (apt), and custom application logs
# Data Collection Rules (DCR) must target Log Analytics workspace
# Example logs: /var/log/syslog, /var/log/auth.log, /var/log/apt/history.log, /var/log/nginx/*.log

# TODO: Configure VM Insights for performance metrics and dependency mapping (optional)

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "azurerm_client_config" "current" {}
