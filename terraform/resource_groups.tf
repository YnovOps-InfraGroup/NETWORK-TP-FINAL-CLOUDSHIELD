# ============================================================
# RESOURCE GROUPS - Cloud Shield
# Toutes les ressources dans un seul RG (PoC)
# ============================================================

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}
