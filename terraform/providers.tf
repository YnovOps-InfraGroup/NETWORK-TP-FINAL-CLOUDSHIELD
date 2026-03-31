# ============================================================
# PROVIDER & BACKEND — Cloud Shield Landing Zone
# Projet : Migration FinTech Global vers Azure
# ============================================================

terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Backend local par défaut — switcher vers azurerm pour production
  # backend "azurerm" {
  #   resource_group_name  = "RG-CORE-STORAGE"
  #   storage_account_name = "stoagreg3sr"
  #   container_name       = "tfstate"
  #   key                  = "cloudshield/terraform.tfstate"
  #   use_azuread_auth     = true
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
