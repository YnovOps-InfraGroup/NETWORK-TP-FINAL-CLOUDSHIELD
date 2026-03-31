# ============================================================
# AZURE BASTION — Administration sécurisée sans IP publique
# ANSSI R14/R28 : Authentification forte + flux admin protégés
# Exigence : Aucun port SSH/RDP exposé sur Internet
# ============================================================

# ── IP Publique Azure Bastion ─────────────────────────────────────────────────
resource "azurerm_public_ip" "bastion_pip" {
  count = var.deploy_bastion ? 1 : 0

  name                = "pip-bastion-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# ── Azure Bastion (Basic — FinOps) ────────────────────────────────────────────
# Permet SSH/RDP via le portail Azure sans exposer de port public
resource "azurerm_bastion_host" "bastion" {
  count = var.deploy_bastion ? 1 : 0

  name                = "bastion-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.hub_bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
  }

  tags = var.tags
}
