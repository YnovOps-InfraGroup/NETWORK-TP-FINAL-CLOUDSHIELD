# ============================================================
# PaaS - Storage, SQL, Private Endpoints, DNS Privées
# ANSSI R15 : Protection des accès aux services sensibles
# Exigence 5 : Zéro endpoint public, accès privé uniquement
# ============================================================

# ==============================================================================
# STORAGE ACCOUNT - Sauvegardes (accès public OFF)
# ==============================================================================

resource "azurerm_storage_account" "backup" {
  count = var.deploy_paas ? 1 : 0

  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Sécurité : zero accès public (ANSSI R15 / Exigence 5)
  public_network_access_enabled   = false
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }

  tags = var.tags
}

# ==============================================================================
# AZURE SQL SERVER - Base de données managée (accès public OFF)
# ==============================================================================

resource "azurerm_mssql_server" "sql" {
  count = var.deploy_paas ? 1 : 0

  name                         = local.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

  # Zéro inbound public (Exigence 5)
  public_network_access_enabled = false

  tags = var.tags
}

# Checkov CKV_AZURE_23/24 : Auditing SQL Server Log Analytics
resource "azurerm_mssql_server_extended_auditing_policy" "sql_audit" {
  count = var.deploy_paas && var.deploy_observability ? 1 : 0

  server_id                               = azurerm_mssql_server.sql[0].id
  log_monitoring_enabled                  = true
  storage_endpoint                        = azurerm_storage_account.backup[0].primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.backup[0].primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 90
}

resource "azurerm_mssql_database" "fintechdb" {
  count = var.deploy_paas ? 1 : 0

  name      = "fintechdb"
  server_id = azurerm_mssql_server.sql[0].id
  sku_name  = "Basic" # FinOps : SKU le moins cher (~€4/mois)

  tags = var.tags
}

# ==============================================================================
# PRIVATE DNS ZONES - Résolution interne vers Private Endpoints
# ==============================================================================

# DNS Zone - Blob Storage
resource "azurerm_private_dns_zone" "blob" {
  count = var.deploy_paas ? 1 : 0

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# DNS Zone - Azure SQL
resource "azurerm_private_dns_zone" "sql" {
  count = var.deploy_paas ? 1 : 0

  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Liens DNS VNets (résolution depuis Spoke-Data + Hub) ───────────────────

resource "azurerm_private_dns_zone_virtual_network_link" "blob_spoke_data" {
  count = var.deploy_paas ? 1 : 0

  name                  = "pdnslink-blob-spoke-data"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = azurerm_virtual_network.spoke_data.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_hub" {
  count = var.deploy_paas ? 1 : 0

  name                  = "pdnslink-blob-hub"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_spoke_data" {
  count = var.deploy_paas ? 1 : 0

  name                  = "pdnslink-sql-spoke-data"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql[0].name
  virtual_network_id    = azurerm_virtual_network.spoke_data.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_hub" {
  count = var.deploy_paas ? 1 : 0

  name                  = "pdnslink-sql-hub"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}

# ==============================================================================
# PRIVATE ENDPOINTS - Accès privé aux services PaaS
# ==============================================================================

# PE Blob Storage ───────────────────────────────────────────────────────────
resource "azurerm_private_endpoint" "pe_blob" {
  count = var.deploy_paas ? 1 : 0

  name                = "pe-blob-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.data_pe.id

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.backup[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnsz-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }

  tags = var.tags
}

# PE Azure SQL ──────────────────────────────────────────────────────────────
resource "azurerm_private_endpoint" "pe_sql" {
  count = var.deploy_paas ? 1 : 0

  name                = "pe-sql-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.data_pe.id

  private_service_connection {
    name                           = "psc-sql"
    private_connection_resource_id = azurerm_mssql_server.sql[0].id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnsz-sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql[0].id]
  }

  tags = var.tags
}
