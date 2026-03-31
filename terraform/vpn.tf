# ============================================================
# VPN - Hybridation IPsec IKEv2 + BGP
# ANSSI R25 : Chiffrement des interconnexions reseau
# Exigence 2 : Canal securise Hub - OnPrem (Lyon)
# Cout : ~0,38 EUR/h par Gateway - deployer en dernier
# ============================================================

# --- IP PUBLIQUES - VPN Gateways ---

resource "azurerm_public_ip" "vpn_hub_pip" {
  count = var.deploy_vpn_gateways ? 1 : 0

  name                = "pip-vpngw-hub-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "vpn_onprem_pip" {
  count = var.deploy_vpn_gateways ? 1 : 0

  name                = "pip-vpngw-onprem-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# --- VPN GATEWAYS ---

# VPN Gateway Hub (BGP AS 65001)
resource "azurerm_virtual_network_gateway" "hub_vpn_gw" {
  count = var.deploy_vpn_gateways ? 1 : 0

  name                = "vpngw-hub-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false
  bgp_enabled         = true

  bgp_settings {
    asn = var.hub_bgp_asn
  }

  ip_configuration {
    name                 = "vpngw-hub-ipconfig"
    public_ip_address_id = azurerm_public_ip.vpn_hub_pip[0].id
    subnet_id            = azurerm_subnet.hub_gateway.id
  }

  tags = var.tags
}

# VPN Gateway OnPrem simulee (BGP AS 65002)
resource "azurerm_virtual_network_gateway" "onprem_vpn_gw" {
  count = var.deploy_vpn_gateways ? 1 : 0

  name                = "vpngw-onprem-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false
  bgp_enabled         = true

  bgp_settings {
    asn = var.onprem_bgp_asn
  }

  ip_configuration {
    name                 = "vpngw-onprem-ipconfig"
    public_ip_address_id = azurerm_public_ip.vpn_onprem_pip[0].id
    subnet_id            = azurerm_subnet.onprem_gateway.id
  }

  tags = var.tags
}

# --- CONNEXION VPN - IPsec IKEv2 + BGP (bidirectionnelle) ---

# Hub -> OnPrem
resource "azurerm_virtual_network_gateway_connection" "hub_to_onprem" {
  count = var.deploy_vpn_gateways ? 1 : 0

  name                = "cn-vpn-hub-to-onprem"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  type                = "Vnet2Vnet"

  virtual_network_gateway_id      = azurerm_virtual_network_gateway.hub_vpn_gw[0].id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.onprem_vpn_gw[0].id

  shared_key  = var.vpn_shared_key
  bgp_enabled = true

  tags = var.tags
}

# OnPrem -> Hub
resource "azurerm_virtual_network_gateway_connection" "onprem_to_hub" {
  count = var.deploy_vpn_gateways ? 1 : 0

  name                = "cn-vpn-onprem-to-hub"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  type                = "Vnet2Vnet"

  virtual_network_gateway_id      = azurerm_virtual_network_gateway.onprem_vpn_gw[0].id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.hub_vpn_gw[0].id

  shared_key  = var.vpn_shared_key
  bgp_enabled = true

  tags = var.tags
}
