# ============================================================
# LOCALS — Valeurs calculées, conventions de nommage
# ============================================================

locals {
  # Suffixe unique basé sur la subscription (pour noms globalement uniques)
  sub_suffix = substr(replace(var.subscription_id, "-", ""), 0, 8)

  # Nommage des Resource Groups
  rg_name = "rg-${var.project_name}-${var.environment}"

  # Nommage des VNets
  vnet_hub_name        = "vnet-hub-${var.project_name}"
  vnet_spoke_prod_name = "vnet-spoke-prod-${var.project_name}"
  vnet_spoke_data_name = "vnet-spoke-data-${var.project_name}"
  vnet_onprem_name     = "vnet-onprem-sim-${var.project_name}"

  # Nommage PaaS (globalement uniques)
  storage_name     = "st${var.project_name}${local.sub_suffix}"
  storage_log_name = "stlog${var.project_name}${local.sub_suffix}"
  sql_server_name  = "sql-${var.project_name}-${local.sub_suffix}"
}

# Subscription courante (pour RBAC, alertes)
data "azurerm_subscription" "current" {}

# data "azurerm_client_config" "current" {} # Réservé pour Key Vault RBAC futur
