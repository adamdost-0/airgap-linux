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

  # Remote state backend for Azure Government
  # Configure state storage account details in terraform.tfvars
  backend "azurerm" {
    environment = "usgovernment"
    # Populated via backend config file or -backend-config flags:
    # storage_account_name = ""
    # container_name       = "tfstate"
    # key                  = "highside.tfstate"
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

  # Azure Government environment
  # Valid values: usgovernment (IL4/IL5), usgovernmentsecret (IL6), usgovernmenttopsecret (TS/SCI)
  environment = var.azure_government_environment

  # Note: Endpoints automatically adjust based on environment:
  # - usgovernment:         *.usgovcloudapi.net
  # - usgovernmentsecret:   *.microsoftazure.us (air-gapped)
  # - usgovernmenttopsecret: *.microsoftazure.eaglex.ic.gov (air-gapped)
}

provider "random" {}
