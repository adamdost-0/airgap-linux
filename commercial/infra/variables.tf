variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for commercial resources (e.g., eastus, westus2)"
  type        = string
  default     = "eastus"
}

variable "owner" {
  description = "Owner tag value (team or individual)"
  type        = string
}

variable "classification" {
  description = "Data classification (CUI for this project)"
  type        = string
  default     = "CUI"
}

variable "compliance" {
  description = "Compliance level (IL4, IL5, IL6)"
  type        = string
  default     = "IL4"

  validation {
    condition     = contains(["IL4", "IL5", "IL6"], var.compliance)
    error_message = "Compliance must be IL4, IL5, or IL6."
  }
}

variable "aptly_vm_size" {
  description = "VM size for Aptly mirror instance"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "aptly_admin_username" {
  description = "Admin username for Aptly VM (SSH key auth only)"
  type        = string
  default     = "aptlyadmin"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for VM admin access"
  type        = string
  sensitive   = true
}

variable "vnet_address_space" {
  description = "VNet address space CIDR"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aptly_subnet_address_prefix" {
  description = "Aptly VM subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "privatelink_subnet_address_prefix" {
  description = "Private Link / Private Endpoint subnet CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "enable_blob_storage" {
  description = "Enable Azure Blob Storage for Aptly pool (Phase 2)"
  type        = bool
  default     = false
}

variable "aptly_pool_container_name" {
  description = "Blob container name for the Aptly pool when Phase 2 blob storage is enabled"
  type        = string
  default     = "aptly-pool"

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{1,61}[a-z0-9])?$", var.aptly_pool_container_name))
    error_message = "Aptly pool container name must be a valid Azure Storage container name."
  }
}

variable "enable_customer_managed_keys" {
  description = "Enable customer-managed keys (CMK) for encryption at rest"
  type        = bool
  default     = true
}

variable "allowed_source_ips" {
  description = "Source IP ranges allowed for management access (if needed for bastion/jumpbox)"
  type        = list(string)
  default     = []
}

variable "enable_log_analytics" {
  description = "Enable Log Analytics workspace for diagnostics and audit logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention period in days for diagnostic logs (30-730)"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "enable_vm_diagnostics" {
  description = "Enable VM-level diagnostics and system log collection"
  type        = bool
  default     = true
}
