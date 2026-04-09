# ==============================================================================
# ROUTAGE - Route Tables (UDR) - Forced Tunneling
# ANSSI R22/R23 : Tout trafic sortant via Azure Firewall
# ==============================================================================

# Route Table Spoke-Prod
# Applique a snet-prod-web et snet-prod-app
# NOTE: Creee SEULEMENT si deploy_firewall=true pour eviter race condition cloud-init
resource "azurerm_route_table" "rt_spoke_prod" {
  count                         = var.deploy_firewall ? 1 : 0
  name                          = "rt-spoke-prod-to-fw"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  bgp_route_propagation_enabled = false # Empêcher VPN GW d'injecter des routes qui bypassent le FW

  # Route par defaut vers Azure Firewall (egress Internet)
  route {
    name           = "default-to-firewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    # Adresse IP du Firewall si deploy=true, fallback 10.0.1.4 si deploy=false (lab mode)
    next_hop_in_ip_address = var.deploy_firewall ? azurerm_firewall.fw[0].ip_configuration[0].private_ip_address : "10.0.1.4"
  }

  # Route Spoke-Data → Firewall
  route {
    name                   = "spoke-data-via-firewall"
    address_prefix         = var.vnet_spoke_data_cidr
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.deploy_firewall ? azurerm_firewall.fw[0].ip_configuration[0].private_ip_address : "10.0.1.4"
  }

  tags = var.tags
}

# ── Route Table Spoke-Data ────────────────────────────────────────────────────
# Appliquée sur snet-data-db et snet-data-pe
# ⚠ UDR créée SEULEMENT si deploy_firewall=true (cf. raison ci-dessus)
resource "azurerm_route_table" "rt_spoke_data" {
  count                         = var.deploy_firewall ? 1 : 0
  name                          = "rt-spoke-data-to-fw"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  bgp_route_propagation_enabled = false

  # Route par defaut vers Azure Firewall
  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.deploy_firewall ? azurerm_firewall.fw[0].ip_configuration[0].private_ip_address : "10.0.1.4"
  }

  # Route vers Spoke-Prod pour inspection cross-spoke
  route {
    name                   = "spoke-prod-via-firewall"
    address_prefix         = var.vnet_spoke_prod_cidr
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.deploy_firewall ? azurerm_firewall.fw[0].ip_configuration[0].private_ip_address : "10.0.1.4"
  }

  tags = var.tags
}

# ==============================================================================
# ASSOCIATIONS UDR - SUBNETS
# ==============================================================================

resource "azurerm_subnet_route_table_association" "prod_web_rt" {
  count          = var.deploy_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.prod_web.id
  route_table_id = azurerm_route_table.rt_spoke_prod[0].id
}

resource "azurerm_subnet_route_table_association" "prod_app_rt" {
  count          = var.deploy_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.prod_app.id
  route_table_id = azurerm_route_table.rt_spoke_prod[0].id
}

resource "azurerm_subnet_route_table_association" "data_db_rt" {
  count          = var.deploy_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.data_db.id
  route_table_id = azurerm_route_table.rt_spoke_data[0].id
}

resource "azurerm_subnet_route_table_association" "data_pe_rt" {
  count          = var.deploy_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.data_pe.id
  route_table_id = azurerm_route_table.rt_spoke_data[0].id
}
