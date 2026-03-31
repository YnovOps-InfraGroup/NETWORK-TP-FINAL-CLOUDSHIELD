# ============================================================
# OBSERVABILITÉ — Log Analytics, Flow Logs, AMA, DCR, Alertes
# ANSSI R36/R37 : Journalisation centralisée + politique de logs
# ANSSI R40 : Procédure de gestion des incidents
# ============================================================

# ═══════════════════════════════════════════════════════════════
# LOG ANALYTICS WORKSPACE — SIEM Centralisé
# ═══════════════════════════════════════════════════════════════

resource "azurerm_log_analytics_workspace" "law" {
  count = var.deploy_observability ? 1 : 0

  name                = "law-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.law_retention_days
  tags                = var.tags
}

# ═══════════════════════════════════════════════════════════════
# STORAGE ACCOUNT — Archivage long terme des logs
# ═══════════════════════════════════════════════════════════════

resource "azurerm_storage_account" "logs" {
  count = var.deploy_observability ? 1 : 0

  name                     = local.storage_log_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  tags = var.tags
}

# ═══════════════════════════════════════════════════════════════
# NETWORK WATCHER — Prérequis pour Flow Logs
# ═══════════════════════════════════════════════════════════════

# Utilise le Network Watcher existant (Azure en crée 1 automatiquement par région/sub)
data "azurerm_network_watcher" "nw" {
  name                = "NetworkWatcher_francecentral"
  resource_group_name = "NetworkWatcherRG"
}

# ═══════════════════════════════════════════════════════════════
# NSG FLOW LOGS — Capture du trafic réseau
# ═══════════════════════════════════════════════════════════════

# VNet Flow Logs (remplace NSG Flow Logs dépréciés depuis juin 2025)
# Ref: https://learn.microsoft.com/azure/network-watcher/vnet-flow-logs-overview
resource "azurerm_network_watcher_flow_log" "flow_vnet_hub" {
  count = var.deploy_observability ? 1 : 0

  network_watcher_name = data.azurerm_network_watcher.nw.name
  resource_group_name  = data.azurerm_network_watcher.nw.resource_group_name
  name                 = "fl-vnet-hub"

  target_resource_id = azurerm_virtual_network.hub.id
  storage_account_id = azurerm_storage_account.logs[0].id
  enabled            = true
  version            = 2

  retention_policy {
    enabled = true
    days    = 30
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.law[0].workspace_id
    workspace_region      = azurerm_log_analytics_workspace.law[0].location
    workspace_resource_id = azurerm_log_analytics_workspace.law[0].id
    interval_in_minutes   = 10
  }

  tags = var.tags
}

resource "azurerm_network_watcher_flow_log" "flow_vnet_spoke_prod" {
  count = var.deploy_observability ? 1 : 0

  network_watcher_name = data.azurerm_network_watcher.nw.name
  resource_group_name  = data.azurerm_network_watcher.nw.resource_group_name
  name                 = "fl-vnet-spoke-prod"

  target_resource_id = azurerm_virtual_network.spoke_prod.id
  storage_account_id = azurerm_storage_account.logs[0].id
  enabled            = true
  version            = 2

  retention_policy {
    enabled = true
    days    = 30
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.law[0].workspace_id
    workspace_region      = azurerm_log_analytics_workspace.law[0].location
    workspace_resource_id = azurerm_log_analytics_workspace.law[0].id
    interval_in_minutes   = 10
  }

  tags = var.tags
}

# ═══════════════════════════════════════════════════════════════
# DIAGNOSTIC SETTINGS — Firewall, Bastion → Log Analytics
# ═══════════════════════════════════════════════════════════════

resource "azurerm_monitor_diagnostic_setting" "diag_fw" {
  count = var.deploy_observability && var.deploy_firewall ? 1 : 0

  name                       = "diag-fw-law"
  target_resource_id         = azurerm_firewall.fw[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law[0].id

  enabled_log { category = "AzureFirewallApplicationRule" }
  enabled_log { category = "AzureFirewallNetworkRule" }
  enabled_log { category = "AzureFirewallDnsProxy" }

  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "diag_bastion" {
  count = var.deploy_observability && var.deploy_bastion ? 1 : 0

  name                       = "diag-bastion-law"
  target_resource_id         = azurerm_bastion_host.bastion[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law[0].id

  enabled_log { category = "BastionAuditLogs" }
}

# ═══════════════════════════════════════════════════════════════
# AZURE MONITOR AGENT (AMA) — Collecte logs VMs
# ═══════════════════════════════════════════════════════════════

resource "azurerm_virtual_machine_extension" "ama_web" {
  count = var.deploy_observability ? 1 : 0

  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm_web.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.tags
}

resource "azurerm_virtual_machine_extension" "ama_app" {
  count = var.deploy_observability ? 1 : 0

  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm_app.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.tags
}

resource "azurerm_virtual_machine_extension" "ama_db" {
  count = var.deploy_observability ? 1 : 0

  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm_db.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.tags
}

# ═══════════════════════════════════════════════════════════════
# DATA COLLECTION RULE — Syslog + Performance Linux
# ═══════════════════════════════════════════════════════════════

resource "azurerm_monitor_data_collection_rule" "dcr_linux" {
  count = var.deploy_observability ? 1 : 0

  name                = "dcr-linux-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "Linux"

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law[0].id
      name                  = "law-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["law-destination"]
  }

  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["law-destination"]
  }

  data_sources {
    syslog {
      facility_names = ["auth", "authpriv", "daemon", "kern", "syslog", "user", "cron"]
      log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
      streams        = ["Microsoft-Syslog"]
      name           = "syslog-source"
    }

    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor Information(_Total)\\% Processor Time",
        "\\Memory\\% Used Memory",
        "\\Logical Disk(*)\\% Used Space",
        "\\Network(*)\\Total Bytes Transmitted",
        "\\Network(*)\\Total Bytes Received",
      ]
      name = "perf-source"
    }
  }

  tags = var.tags
}

# ── Associations DCR → VMs ────────────────────────────────────────────────────

resource "azurerm_monitor_data_collection_rule_association" "dcr_web" {
  count = var.deploy_observability ? 1 : 0

  name                    = "dcr-assoc-vm-web"
  target_resource_id      = azurerm_linux_virtual_machine.vm_web.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr_linux[0].id

  depends_on = [azurerm_virtual_machine_extension.ama_web]
}

resource "azurerm_monitor_data_collection_rule_association" "dcr_app" {
  count = var.deploy_observability ? 1 : 0

  name                    = "dcr-assoc-vm-app"
  target_resource_id      = azurerm_linux_virtual_machine.vm_app.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr_linux[0].id

  depends_on = [azurerm_virtual_machine_extension.ama_app]
}

resource "azurerm_monitor_data_collection_rule_association" "dcr_db" {
  count = var.deploy_observability ? 1 : 0

  name                    = "dcr-assoc-vm-db"
  target_resource_id      = azurerm_linux_virtual_machine.vm_db.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr_linux[0].id

  depends_on = [azurerm_virtual_machine_extension.ama_db]
}

# ═══════════════════════════════════════════════════════════════
# ALERTES — Action Group + Rules
# ═══════════════════════════════════════════════════════════════

# ── Action Group SecOps ───────────────────────────────────────────────────────
resource "azurerm_monitor_action_group" "secops" {
  count = var.deploy_observability ? 1 : 0

  name                = "AG-SecOps-${var.project_name}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "secops"

  email_receiver {
    name                    = "secops-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = var.tags
}

# ── Alerte : modification règle NSG (War Room) ───────────────────────────────
resource "azurerm_monitor_activity_log_alert" "nsg_rule_change" {
  count = var.deploy_observability ? 1 : 0

  name                = "ala-nsg-rule-change"
  resource_group_name = azurerm_resource_group.main.name
  location            = "global"
  scopes              = [data.azurerm_subscription.current.id]
  description         = "Alerte : règle NSG modifiée — risque d'ouverture non autorisée"

  criteria {
    operation_name = "Microsoft.Network/networkSecurityGroups/securityRules/write"
    category       = "Administrative"
  }

  action {
    action_group_id = azurerm_monitor_action_group.secops[0].id
  }

  tags = var.tags
}

# ── Alerte : suppression de ressource réseau ──────────────────────────────────
resource "azurerm_monitor_activity_log_alert" "network_delete" {
  count = var.deploy_observability ? 1 : 0

  name                = "ala-network-resource-delete"
  resource_group_name = azurerm_resource_group.main.name
  location            = "global"
  scopes              = [azurerm_resource_group.main.id]
  description         = "Alerte : suppression d'une ressource réseau"

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Network/virtualNetworks/delete"
  }

  action {
    action_group_id = azurerm_monitor_action_group.secops[0].id
  }

  tags = var.tags
}

# ── Alerte : modification Firewall Policy ─────────────────────────────────────
resource "azurerm_monitor_activity_log_alert" "fw_policy_change" {
  count = var.deploy_observability && var.deploy_firewall ? 1 : 0

  name                = "ala-fw-policy-change"
  resource_group_name = azurerm_resource_group.main.name
  location            = "global"
  scopes              = [data.azurerm_subscription.current.id]
  description         = "Alerte : règle Firewall modifiée — vérification requise"

  criteria {
    operation_name = "Microsoft.Network/firewallPolicies/ruleCollectionGroups/write"
    category       = "Administrative"
  }

  action {
    action_group_id = azurerm_monitor_action_group.secops[0].id
  }

  tags = var.tags
}

# ── Alerte : Azure Service Health ─────────────────────────────────────────────
resource "azurerm_monitor_activity_log_alert" "service_health" {
  count = var.deploy_observability ? 1 : 0

  name                = "ala-azure-service-health"
  resource_group_name = azurerm_resource_group.main.name
  location            = "global"
  scopes              = [data.azurerm_subscription.current.id]
  description         = "Incident Azure Service Health sur France Central"

  criteria {
    category = "ServiceHealth"
    service_health {
      locations = [azurerm_resource_group.main.location]
      events    = ["Incident", "Maintenance", "ActionRequired"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.secops[0].id
  }

  tags = var.tags
}
