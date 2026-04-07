# ============================================================
# RÉSEAU — VNets, Subnets, Peerings
# ANSSI R19 : Segmentation réseau — Hub & Spoke
# Architecture : 4 VNets isolés (Hub, Prod, Data, OnPrem)
# ============================================================

# ═══════════════════════════════════════════════════════════════
# VNETS
# ═══════════════════════════════════════════════════════════════

# ── Hub VNet — Sécurité centralisée, egress, hybridation ─────────────────────
resource "azurerm_virtual_network" "hub" {
  name                = local.vnet_hub_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_hub_cidr]
  tags                = var.tags
}

# ── Spoke Production — Application 3-tiers ───────────────────────────────────
resource "azurerm_virtual_network" "spoke_prod" {
  name                = local.vnet_spoke_prod_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_spoke_prod_cidr]
  tags                = var.tags
}

# ── Spoke Data — CDE PCI-DSS (DB + Private Endpoints) ───────────────────────
resource "azurerm_virtual_network" "spoke_data" {
  name                = local.vnet_spoke_data_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_spoke_data_cidr]
  tags                = var.tags
}

# ── OnPrem Simulation — Site de Lyon ─────────────────────────────────────────
resource "azurerm_virtual_network" "onprem" {
  name                = local.vnet_onprem_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_onprem_cidr]
  tags                = var.tags
}

# ═══════════════════════════════════════════════════════════════
# SUBNETS — HUB
# ═══════════════════════════════════════════════════════════════

# ⚠ Nom EXACT obligatoire : "AzureFirewallSubnet" — /26 minimum
resource "azurerm_subnet" "hub_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_hub_firewall]
}

# ⚠ Nom EXACT obligatoire : "AzureBastionSubnet" — /26 minimum
resource "azurerm_subnet" "hub_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_hub_bastion]
}

# ⚠ Nom EXACT obligatoire : "GatewaySubnet" — /27 minimum
resource "azurerm_subnet" "hub_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_hub_gateway]
}

# ═══════════════════════════════════════════════════════════════
# SUBNETS — SPOKE PRODUCTION
# ═══════════════════════════════════════════════════════════════

# Tier 1 — Présentation (vm-web, Flask)
resource "azurerm_subnet" "prod_web" {
  name                 = "snet-prod-web"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke_prod.name
  address_prefixes     = [var.subnet_prod_web]
}

# Tier 2 — Traitement (vm-app, logique métier)
resource "azurerm_subnet" "prod_app" {
  name                 = "snet-prod-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke_prod.name
  address_prefixes     = [var.subnet_prod_app]
}

# Subnet dédié Application Gateway WAF
resource "azurerm_subnet" "prod_waf" {
  name                 = "snet-prod-waf"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke_prod.name
  address_prefixes     = [var.subnet_prod_waf]
}

# ═══════════════════════════════════════════════════════════════
# SUBNETS — SPOKE DATA (CDE PCI-DSS)
# ═══════════════════════════════════════════════════════════════

# Tier 3 — Stockage (vm-db, PostgreSQL)
resource "azurerm_subnet" "data_db" {
  name                 = "snet-data-db"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke_data.name
  address_prefixes     = [var.subnet_data_db]
}

# Private Endpoints PaaS (Storage, SQL)
resource "azurerm_subnet" "data_pe" {
  name                 = "snet-data-pe"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke_data.name
  address_prefixes     = [var.subnet_data_pe]
}

# ═══════════════════════════════════════════════════════════════
# SUBNETS — ONPREM SIMULATION
# ═══════════════════════════════════════════════════════════════

# ⚠ Nom EXACT obligatoire : "GatewaySubnet"
resource "azurerm_subnet" "onprem_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = [var.subnet_onprem_gateway]
}

# Serveurs On-Premises simulés
#checkov:skip=CKV2_AZURE_31:Simulation subnet OnPrem — pas de NSG requis en environnement lab
resource "azurerm_subnet" "onprem_srv" {
  name                 = "snet-onprem-srv"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = [var.subnet_onprem_srv]
}

# ═══════════════════════════════════════════════════════════════
# VNET PEERINGS — Hub & Spoke
# ANSSI R19 : Cloisonnement avec transit centralisé
# ═══════════════════════════════════════════════════════════════

# ── Hub → Spoke-Prod ──────────────────────────────────────────────────────────
resource "azurerm_virtual_network_peering" "hub_to_spoke_prod" {
  name                         = "peer-hub-to-spoke-prod"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_prod.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.deploy_vpn_gateways
}

# ── Spoke-Prod → Hub ──────────────────────────────────────────────────────────
resource "azurerm_virtual_network_peering" "spoke_prod_to_hub" {
  name                         = "peer-spoke-prod-to-hub"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.spoke_prod.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = var.deploy_vpn_gateways

  depends_on = [azurerm_virtual_network_gateway.hub_vpn_gw]
}

# ── Hub → Spoke-Data ──────────────────────────────────────────────────────────
resource "azurerm_virtual_network_peering" "hub_to_spoke_data" {
  name                         = "peer-hub-to-spoke-data"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_data.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.deploy_vpn_gateways
}

# ── Spoke-Data → Hub ──────────────────────────────────────────────────────────
resource "azurerm_virtual_network_peering" "spoke_data_to_hub" {
  name                         = "peer-spoke-data-to-hub"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.spoke_data.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = var.deploy_vpn_gateways

  depends_on = [azurerm_virtual_network_gateway.hub_vpn_gw]
}
