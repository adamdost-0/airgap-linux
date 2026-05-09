terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state backend for Azure Commercial
  # Configure state storage account details in terraform.tfvars
  backend "azurerm" {
    # environment is not needed for Azure Commercial (default)
    # Populated via backend config file or -backend-config flags:
    # storage_account_name = ""
    # container_name       = "tfstate"
    # key                  = "commercial.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }

  # Azure Commercial (default) — no environment override needed
  # All resources will use public cloud endpoints (.windows.net, .azure.com)
}

provider "random" {}
