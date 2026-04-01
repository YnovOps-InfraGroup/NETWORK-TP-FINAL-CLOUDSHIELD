# ============================================================
# BACKEND — Centralisation du State Terraform dans Azure
# ============================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "RG-CORE-STORAGE"
    storage_account_name = "stoagreg3sr"
    container_name       = "tfstate"
    key                  = "cloudshield/terraform.tfstate"
    use_azuread_auth     = true
  }
}
