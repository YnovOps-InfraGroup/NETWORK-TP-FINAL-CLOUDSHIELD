# ============================================================
# SÉCURITÉ — NSGs + ASGs — Micro-segmentation Zero Trust
# ANSSI R19 : Cloisonnement strict entre tiers
# Exigence 3c : Pas d'IP statiques → utilisation des ASG
# ============================================================

# ═══════════════════════════════════════════════════════════════
# APPLICATION SECURITY GROUPS — Labels logiques Zero Trust
# ═══════════════════════════════════════════════════════════════

resource "azurerm_application_security_group" "asg_web" {
  name                = "asg-web"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_application_security_group" "asg_app" {
  name                = "asg-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_application_security_group" "asg_db" {
  name                = "asg-db"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Phase 4 TP : asg-bastion obligatoire
resource "azurerm_application_security_group" "asg_bastion" {
  name                = "asg-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# ═══════════════════════════════════════════════════════════════
# NSG — SUBNET WEB (Tier 1 — Présentation)
# Autorise : WAF → Web (HTTP/80), Bastion → SSH
# Refuse : tout le reste (deny-all explicit)
# ═══════════════════════════════════════════════════════════════

resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-prod-web"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # WAF (Application Gateway) → Serveurs Web
  security_rule {
    name                                       = "Allow-HTTP-from-WAF"
    priority                                   = 100
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_ranges                    = ["80", "443"]
    source_address_prefix                      = var.subnet_prod_waf
    destination_application_security_group_ids = [azurerm_application_security_group.asg_web.id]
  }

  # Azure Load Balancer health probes (obligatoire pour AppGW)
  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Zero Trust : refus explicite de tout le reste en inbound (prio 4000 = TP)
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

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_web_assoc" {
  subnet_id                 = azurerm_subnet.prod_web.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

# ═══════════════════════════════════════════════════════════════
# NSG — SUBNET APP (Tier 2 — Traitement)
# Autorise : asg-web → asg-app (TCP/8080)
# Refuse : tout le reste
# ═══════════════════════════════════════════════════════════════

resource "azurerm_network_security_group" "nsg_app" {
  name                = "nsg-prod-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Web → App (API interne, TCP 8080) — utilise ASG (pas d'IP statique)
  security_rule {
    name                                       = "Allow-TCP8080-from-Web"
    priority                                   = 100
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_range                     = "8080"
    source_application_security_group_ids      = [azurerm_application_security_group.asg_web.id]
    destination_application_security_group_ids = [azurerm_application_security_group.asg_app.id]
  }

  # Zero Trust : deny-all inbound (prio 4000 = TP)
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

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_app_assoc" {
  subnet_id                 = azurerm_subnet.prod_app.id
  network_security_group_id = azurerm_network_security_group.nsg_app.id
}

# ═══════════════════════════════════════════════════════════════
# NSG — SUBNET DB (Tier 3 — Stockage, CDE PCI-DSS)
# Autorise : asg-app → asg-db (TCP/5432 PostgreSQL)
# Refuse : tout inbound + Internet outbound
# ═══════════════════════════════════════════════════════════════

resource "azurerm_network_security_group" "nsg_db" {
  name                = "nsg-data-db"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # App → DB (PostgreSQL 5432) — cross-spoke via Firewall
  # Note : ASG cross-VNet non supporté → utilisation du CIDR subnet
  security_rule {
    name                                       = "Allow-PostgreSQL-from-App"
    priority                                   = 100
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_range                     = "5432"
    source_address_prefix                      = var.subnet_prod_app
    destination_application_security_group_ids = [azurerm_application_security_group.asg_db.id]
  }

  # Deny-all inbound (prio 4000 = TP)
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

  # ANSSI R22 : Interdire Internet sortant depuis la zone CDE
  security_rule {
    name                       = "Deny-Internet-Outbound"
    priority                   = 4001
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_db_assoc" {
  subnet_id                 = azurerm_subnet.data_db.id
  network_security_group_id = azurerm_network_security_group.nsg_db.id
}

# ═══════════════════════════════════════════════════════════════
# NSG — SUBNET WAF (Application Gateway)
# Règles spécifiques Microsoft obligatoires pour AppGW v2
# ═══════════════════════════════════════════════════════════════

resource "azurerm_network_security_group" "nsg_waf" {
  name                = "nsg-prod-waf"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Obligatoire AppGW v2 : ports de gestion 65200-65535
  security_rule {
    name                       = "Allow-GatewayManager"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  # Trafic HTTPS entrant depuis Internet (clients web)
  security_rule {
    name                       = "Allow-HTTPS-Internet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Health probes Azure Load Balancer
  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_waf_assoc" {
  subnet_id                 = azurerm_subnet.prod_waf.id
  network_security_group_id = azurerm_network_security_group.nsg_waf.id
}

# ═══════════════════════════════════════════════════════════════
# NSG — SUBNET PE (Private Endpoints)
# Accès HTTPS depuis le VNet uniquement
# ═══════════════════════════════════════════════════════════════

resource "azurerm_network_security_group" "nsg_pe" {
  name                = "nsg-data-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-HTTPS-from-VNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # SQL TDS (1433)
  security_rule {
    name                       = "Allow-SQL-from-VNet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

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

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_pe_assoc" {
  subnet_id                 = azurerm_subnet.data_pe.id
  network_security_group_id = azurerm_network_security_group.nsg_pe.id
}
