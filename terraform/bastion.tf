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

# ── Azure Bastion (Standard) ──────────────────────────────────────────────────
# fix(bastion): SKU Standard requis pour az network bastion tunnel (native client)
# Root cause #1 : Basic ne supporte pas le tunneling natif CLI
# ANSSI R28 : Accès admin exclusivement via Bastion, aucun SSH direct depuis Internet

resource "azurerm_bastion_host" "bastion" {
  count = var.deploy_bastion ? 1 : 0

  name                = "bastion-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  # Standard requis pour : tunneling natif CLI, native client, file copy
  sku               = "Standard"
  tunneling_enabled = true

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.hub_bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
  }

  tags = var.tags
}

# ═══════════════════════════════════════════════════════════════
# NSG — AzureBastionSubnet (Phase 4 TP — règles exactes Microsoft)
# Ref : https://learn.microsoft.com/azure/bastion/bastion-nsg
# ═══════════════════════════════════════════════════════════════

resource "azurerm_network_security_group" "nsg_bastion" {
  count = var.deploy_bastion ? 1 : 0

  name                = "nsg-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # ── INBOUND ─────────────────────────────────────────────────

  security_rule {
    name                       = "Allow-HTTPS-Internet-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }


  security_rule {
    name                       = "Allow-GatewayManager-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureLoadBalancer-Inbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-BastionHostCommunication-Inbound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Deny-all inbound
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ── OUTBOUND ────────────────────────────────────────────────

  security_rule {
    name                       = "Allow-SSH-RDP-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow-AzureCloud-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
  security_rule {
    name                       = "Allow-BastionHostCommunication-Outbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }


  security_rule {
    name                       = "Allow-HTTP-Outbound"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_bastion_assoc" {
  count = var.deploy_bastion ? 1 : 0

  subnet_id                 = azurerm_subnet.hub_bastion.id
  network_security_group_id = azurerm_network_security_group.nsg_bastion[0].id
}
