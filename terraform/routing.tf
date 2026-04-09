# ============================================================
# ROUTAGE — Route Tables (UDR) — Forced Tunneling
# ANSSI R22/R23 : Tout trafic sortant via Azure Firewall
# Le trafic inter-spokes passe aussi par le Firewall (inspection)
# ============================================================

# ── Route Table Spoke-Prod ────────────────────────────────────────────────────
# Appliquée sur snet-prod-web et snet-prod-app
# ⚠ UDR créée SEULEMENT si deploy_firewall=true
# Raison : Sans firewall, les UDR créent une race condition au cloud-init (blackhole)
# Solution : terraform apply avec deploy_firewall=false → cloud-init OK → deploy_firewall=true (2e apply)
resource "azurerm_route_table" "rt_spoke_prod" {
  count                         = var.deploy_firewall ? 1 : 0
  name                          = "rt-spoke-prod-to-fw"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  bgp_route_propagation_enabled = false # Empêcher VPN GW d'injecter des routes qui bypassent le FW

  # Route par défaut → Azure Firewall (egress Internet)
  route {
    name           = "default-to-firewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    # ⚠ LAB ONLY — 10.0.1.4 est l'IP fallback quand deploy_firewall=false
    # Le trafic sera blackholé intentionnellement (subnets isolés en lab, aucun egress)
    next_hop_in_ip_address = var.deploy_firewall ? azurerm_firewall.fw[0].ip_configuration[0].private_ip_address : "10.0.1.4"
  }

  # Route Spoke-Data → Firewall (forcer l'inspection cross-spoke)
  route {
    name           = "spoke-data-via-firewall"
    address_prefix = var.vnet_spoke_data_cidr
    next_hop_type  = "VirtualAppliance"
    # ⚠ LAB ONLY — voir commentaire ci-dessus
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

  # Route par défaut → Azure Firewall
  route {
    name           = "default-to-firewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    # ⚠ LAB ONLY — 10.0.1.4 est l'IP fallback quand deploy_firewall=false
    # Le trafic sera blackholé intentionnellement (subnets isolés en lab, aucun egress)
    next_hop_in_ip_address = var.deploy_firewall ? azurerm_firewall.fw[0].ip_configuration[0].private_ip_address : "10.0.1.4"
  }

  # Route Spoke-Prod → Firewall (inspection cross-spoke)
  route {
    name           = "spoke-prod-via-firewall"
    address_prefix = var.vnet_spoke_prod_cidr
    next_hop_type  = "VirtualAppliance"
    # ⚠ LAB ONLY — voir commentaire ci-dessus
    next_hop_in_ip_address = var.deploy_firewall ? azurerm_firewall.fw[0].ip_configuration[0].private_ip_address : "10.0.1.4"
  }

  tags = var.tags
}

# ═══════════════════════════════════════════════════════════════
# ASSOCIATIONS UDR → SUBNETS
# ═══════════════════════════════════════════════════════════════

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
