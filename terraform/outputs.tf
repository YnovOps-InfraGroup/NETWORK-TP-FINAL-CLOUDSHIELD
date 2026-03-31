# ============================================================
# OUTPUTS — Cloud Shield Landing Zone
# Valeurs exportées pour validation et recette
# ============================================================

# ── Resource Group ────────────────────────────────────────────────────────────
output "resource_group_name" {
  description = "Nom du Resource Group principal"
  value       = azurerm_resource_group.main.name
}

# ── VNets ─────────────────────────────────────────────────────────────────────
output "vnets" {
  description = "CIDRs des VNets déployés"
  value = {
    hub        = tolist(azurerm_virtual_network.hub.address_space)[0]
    spoke_prod = tolist(azurerm_virtual_network.spoke_prod.address_space)[0]
    spoke_data = tolist(azurerm_virtual_network.spoke_data.address_space)[0]
    onprem     = tolist(azurerm_virtual_network.onprem.address_space)[0]
  }
}

# ── Subnets ───────────────────────────────────────────────────────────────────
output "subnets" {
  description = "CIDRs de tous les subnets"
  value = {
    hub_firewall = tolist(azurerm_subnet.hub_firewall.address_prefixes)[0]
    hub_bastion  = tolist(azurerm_subnet.hub_bastion.address_prefixes)[0]
    hub_gateway  = tolist(azurerm_subnet.hub_gateway.address_prefixes)[0]
    prod_web     = tolist(azurerm_subnet.prod_web.address_prefixes)[0]
    prod_app     = tolist(azurerm_subnet.prod_app.address_prefixes)[0]
    prod_waf     = tolist(azurerm_subnet.prod_waf.address_prefixes)[0]
    data_db      = tolist(azurerm_subnet.data_db.address_prefixes)[0]
    data_pe      = tolist(azurerm_subnet.data_pe.address_prefixes)[0]
    onprem_srv   = tolist(azurerm_subnet.onprem_srv.address_prefixes)[0]
  }
}

# ── IPs privées VMs ───────────────────────────────────────────────────────────
output "vm_private_ips" {
  description = "IPs privées des VMs (aucune IP publique — ANSSI R22)"
  value = {
    vm_web    = azurerm_network_interface.nic_web.private_ip_address
    vm_app    = azurerm_network_interface.nic_app.private_ip_address
    vm_db     = azurerm_network_interface.nic_db.private_ip_address
    vm_onprem = azurerm_network_interface.nic_onprem.private_ip_address
  }
}

# ── Firewall ──────────────────────────────────────────────────────────────────
output "firewall_private_ip" {
  description = "IP privée Azure Firewall (next-hop des UDR)"
  value       = var.deploy_firewall ? azurerm_firewall.fw[0].ip_configuration[0].private_ip_address : "N/A (firewall non déployé)"
}

output "firewall_public_ip" {
  description = "IP publique Azure Firewall (egress Internet)"
  value       = var.deploy_firewall ? azurerm_public_ip.fw_pip[0].ip_address : "N/A"
}

# ── Bastion ───────────────────────────────────────────────────────────────────
output "bastion_name" {
  description = "Nom Azure Bastion (pour commande az network bastion ssh)"
  value       = var.deploy_bastion ? azurerm_bastion_host.bastion[0].name : "N/A"
}

# ── WAF ───────────────────────────────────────────────────────────────────────
output "waf_public_ip" {
  description = "IP publique Application Gateway WAF (accès web)"
  value       = var.deploy_waf ? azurerm_public_ip.waf_pip[0].ip_address : "N/A"
}

# ── PaaS ──────────────────────────────────────────────────────────────────────
output "private_endpoint_ips" {
  description = "IPs privées des Private Endpoints PaaS"
  value = var.deploy_paas ? {
    blob = azurerm_private_endpoint.pe_blob[0].private_service_connection[0].private_ip_address
    sql  = azurerm_private_endpoint.pe_sql[0].private_service_connection[0].private_ip_address
  } : {}
}

# ── Commandes utiles (Bastion SSH) ────────────────────────────────────────────
output "bastion_ssh_vm_web" {
  description = "Commande SSH via Bastion vers vm-web"
  value       = var.deploy_bastion ? "az network bastion ssh --name ${azurerm_bastion_host.bastion[0].name} --resource-group ${azurerm_resource_group.main.name} --target-resource-id ${azurerm_linux_virtual_machine.vm_web.id} --auth-type ssh-key --username ${var.vm_admin_username} --ssh-key ~/.ssh/id_ed25519" : "N/A"
}

output "bastion_ssh_vm_db" {
  description = "Commande SSH via Bastion vers vm-db"
  value       = var.deploy_bastion ? "az network bastion ssh --name ${azurerm_bastion_host.bastion[0].name} --resource-group ${azurerm_resource_group.main.name} --target-resource-id ${azurerm_linux_virtual_machine.vm_db.id} --auth-type ssh-key --username ${var.vm_admin_username} --ssh-key ~/.ssh/id_ed25519" : "N/A"
}

# ── WAF test ──────────────────────────────────────────────────────────────────
output "waf_curl_test" {
  description = "Commande curl pour tester le WAF depuis l'extérieur"
  value       = var.deploy_waf ? "curl -v http://${azurerm_public_ip.waf_pip[0].ip_address}/" : "N/A"
}

# ── WAF SQL injection test ────────────────────────────────────────────────────
output "waf_sqli_test" {
  description = "Test d'injection SQL (doit être bloqué par le WAF OWASP 3.2)"
  value       = var.deploy_waf ? "curl -v 'http://${azurerm_public_ip.waf_pip[0].ip_address}/?id=1%20OR%201=1'" : "N/A"
}
