# ============================================================
# AZURE FIREWALL - Inspection centralisée de tout le trafic
# ANSSI R22/R23/R24 : Filtrage sortant + proxy + contrôle flux
# Exigence 4b : Tout trafic egress inspecté par FW centralisé
# ============================================================

# IP Publique Azure Firewall ────────────────────────────────────────────────
resource "azurerm_public_ip" "fw_pip" {
  count = var.deploy_firewall ? 1 : 0

  name                = "pip-firewall-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Firewall Policy (Standard + Threat Intelligence) ─────────────────────────
resource "azurerm_firewall_policy" "fw_policy" {
  count = var.deploy_firewall ? 1 : 0

  name                = "fp-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  # DNS proxy : résolution DNS centralisée via le Firewall
  dns {
    proxy_enabled = true
    servers       = ["168.63.129.16"] # Azure DNS
  }

  # Threat Intelligence : alerte sur les IP/domaines malveillants connus
  threat_intelligence_mode = "Alert"

  tags = var.tags
}

# Azure Firewall (Standard) ─────────────────────────────────────────────────
resource "azurerm_firewall" "fw" {
  count = var.deploy_firewall ? 1 : 0

  name                = "fw-${var.project_name}-hub"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.fw_policy[0].id

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.hub_firewall.id
    public_ip_address_id = azurerm_public_ip.fw_pip[0].id
  }

  tags = var.tags
}

# ==============================================================================
# RÈGLES FIREWALL - Deny-all implicite + autorisations ciblées
# ==============================================================================

resource "azurerm_firewall_policy_rule_collection_group" "rules" {
  count = var.deploy_firewall ? 1 : 0

  name               = "rcg-${var.project_name}"
  firewall_policy_id = azurerm_firewall_policy.fw_policy[0].id
  priority           = 200

  # ── Network Rules (L3/L4) ──────────────────────────────────────────────────
  network_rule_collection {
    name     = "nrc-internal-allow"
    priority = 200
    action   = "Allow"

    # DNS vers Azure DNS
    rule {
      name                  = "Allow-DNS-Azure"
      protocols             = ["UDP", "TCP"]
      source_addresses      = [var.vnet_spoke_prod_cidr, var.vnet_spoke_data_cidr]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["53"]
    }

    # NTP (synchronisation horaire - ANSSI R36)
    # Ciblé sur l'IP NTP Azure interne (168.63.129.16) au lieu de * (ANSSI R23 - filtrage sortant)
    # Toutes les VMs Azure utilisent 168.63.129.16 pour NTP par défaut
    rule {
      name                  = "Allow-NTP"
      protocols             = ["UDP"]
      source_addresses      = [var.vnet_spoke_prod_cidr, var.vnet_spoke_data_cidr]
      destination_addresses = ["168.63.129.16"] # Azure NTP interne - remplace * trop permissif
      destination_ports     = ["123"]
    }

    # App DB (PostgreSQL 5432) - cross-spoke via Firewall
    rule {
      name                  = "Allow-App-to-DB-PostgreSQL"
      protocols             = ["TCP"]
      source_addresses      = [var.subnet_prod_app]
      destination_addresses = [var.subnet_data_db]
      destination_ports     = ["5432"]
    }

    # Web App (API 8080) - intra-spoke via Firewall
    rule {
      name                  = "Allow-Web-to-App-API"
      protocols             = ["TCP"]
      source_addresses      = [var.subnet_prod_web]
      destination_addresses = [var.subnet_prod_app]
      destination_ports     = ["8080"]
    }

    # ICMP interne pour diagnostic (Bastion VMs)
    rule {
      name                  = "Allow-ICMP-Internal"
      protocols             = ["ICMP"]
      source_addresses      = [var.vnet_hub_cidr]
      destination_addresses = [var.vnet_spoke_prod_cidr, var.vnet_spoke_data_cidr]
      destination_ports     = ["*"]
    }
  }

  # ── Application Rules (L7 - FQDN) ─────────────────────────────────────────
  application_rule_collection {
    name     = "arc-internet-allow"
    priority = 300
    action   = "Allow"

    rule {
      name = "Allow-Ubuntu-Updates"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses = [var.vnet_spoke_prod_cidr, var.vnet_spoke_data_cidr]
      destination_fqdns = [
        "security.ubuntu.com",
        "archive.ubuntu.com",
        "*.ubuntu.com",
        "*.launchpad.net",
      ]
    }

    # Azure Monitor endpoints (télémétrie AMA)
    rule {
      name = "Allow-Azure-Monitor"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = [var.vnet_spoke_prod_cidr, var.vnet_spoke_data_cidr]
      destination_fqdns = [
        # Control plane AMA - fix(ama): FQDNs manquants qui bloquaient le téléchargement DCR
        "*.handler.control.monitor.azure.com",
        "global.handler.control.monitor.azure.com",
        "francecentral.handler.control.monitor.azure.com",
        # Ingestion logs & métriques
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.monitoring.azure.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "*.blob.core.windows.net",
      ]
    }

    # PyPI + apt pour installation packages applicatifs
    rule {
      name = "Allow-Package-Repos"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = [var.subnet_prod_web, var.subnet_prod_app]
      destination_fqdns = ["pypi.org", "*.pypi.org", "files.pythonhosted.org"]
    }
  }
}
