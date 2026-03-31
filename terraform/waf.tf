# ============================================================
# WAF — Application Gateway v2 (WAF_v2, OWASP 3.2)
# ANSSI R22 : Application web non exposée directement
# Exigence 4a : Trafic intercepté, déchiffré, analysé (anti SQLi)
# ⚠ Coût : ~0,25 €/h (autoscale min=0 = coût minimal au repos)
# ============================================================

# ── WAF Policy (OWASP 3.2 + Bot Protection, mode Prevention) ─────────────────
resource "azurerm_web_application_firewall_policy" "waf_policy" {
  count = var.deploy_waf ? 1 : 0

  name                = "wafpol-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    # OWASP Core Rule Set 3.2 (SQL Injection, XSS, LFI, RFI, etc.)
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
    # Protection anti-bot Microsoft
    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.0"
    }
  }

  tags = var.tags
}

# ── IP publique Application Gateway ──────────────────────────────────────────
resource "azurerm_public_ip" "waf_pip" {
  count = var.deploy_waf ? 1 : 0

  name                = "pip-appgw-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# ── Application Gateway WAF_v2 ────────────────────────────────────────────────
locals {
  appgw_backend_pool_name  = "bepool-vm-web"
  appgw_backend_http_name  = "http-settings-web"
  appgw_frontend_ip_name   = "feip-public"
  appgw_frontend_port_name = "feport-80"
  appgw_listener_name      = "listener-http"
  appgw_rule_name          = "rule-http-web"
  appgw_probe_name         = "probe-http-web"
}

resource "azurerm_application_gateway" "waf" {
  count = var.deploy_waf ? 1 : 0

  name                = "appgw-waf-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  # FinOps : min_capacity=0 → coût minimal au repos (PoC)
  autoscale_configuration {
    min_capacity = 0
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ipconfig"
    subnet_id = azurerm_subnet.prod_waf.id
  }

  frontend_ip_configuration {
    name                 = local.appgw_frontend_ip_name
    public_ip_address_id = azurerm_public_ip.waf_pip[0].id
  }

  frontend_port {
    name = local.appgw_frontend_port_name
    port = 80
  }

  # Backend : IPs privées des VMs Web (pas d'IP publique !)
  backend_address_pool {
    name         = local.appgw_backend_pool_name
    ip_addresses = [azurerm_network_interface.nic_web.private_ip_address]
  }

  backend_http_settings {
    name                  = local.appgw_backend_http_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = local.appgw_probe_name
  }

  # Health probe vers vm-web
  probe {
    name                = local.appgw_probe_name
    protocol            = "Http"
    path                = "/health"
    host                = azurerm_network_interface.nic_web.private_ip_address
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = local.appgw_listener_name
    frontend_ip_configuration_name = local.appgw_frontend_ip_name
    frontend_port_name             = local.appgw_frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.appgw_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.appgw_listener_name
    backend_address_pool_name  = local.appgw_backend_pool_name
    backend_http_settings_name = local.appgw_backend_http_name
    priority                   = 100
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy[0].id

  tags = var.tags
}
