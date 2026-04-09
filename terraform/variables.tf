# ============================================================
# VARIABLES — Cloud Shield Landing Zone
# ============================================================

# ── Identité Azure ────────────────────────────────────────────────────────────
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

# ── Région & Naming ──────────────────────────────────────────────────────────
variable "location" {
  description = "Région Azure de déploiement"
  type        = string
}

variable "project_name" {
  description = "Nom du projet (utilisé dans le nommage des ressources)"
  type        = string
}

variable "environment" {
  description = "Environnement (prod, dev, poc)"
  type        = string
}

variable "tags" {
  description = "Tags communs à toutes les ressources"
  type        = map(string)
  sensitive   = true
}

# ── CIDRs VNets ──────────────────────────────────────────────────────────────
variable "vnet_hub_cidr" {
  description = "CIDR du VNet Hub"
  type        = string
}

variable "vnet_spoke_prod_cidr" {
  description = "CIDR du VNet Spoke Production"
  type        = string
}

variable "vnet_spoke_data_cidr" {
  description = "CIDR du VNet Spoke Data (CDE PCI-DSS)"
  type        = string
}

variable "vnet_onprem_cidr" {
  description = "CIDR du VNet simulant le site On-Premises (Lyon)"
  type        = string
}

# ── CIDRs Subnets Hub ────────────────────────────────────────────────────────
variable "subnet_hub_firewall" {
  description = "CIDR AzureFirewallSubnet (/26 minimum obligatoire)"
  type        = string
}

variable "subnet_hub_bastion" {
  description = "CIDR AzureBastionSubnet (/26 minimum obligatoire)"
  type        = string
}

variable "subnet_hub_gateway" {
  description = "CIDR GatewaySubnet (/27 minimum)"
  type        = string
}

# ── CIDRs Subnets Spoke-Prod ─────────────────────────────────────────────────
variable "subnet_prod_web" {
  description = "CIDR subnet Web (Tier 1 — Présentation)"
  type        = string
}

variable "subnet_prod_app" {
  description = "CIDR subnet App (Tier 2 — Traitement)"
  type        = string
}

variable "subnet_prod_waf" {
  description = "CIDR subnet WAF / Application Gateway"
  type        = string
}

# ── CIDRs Subnets Spoke-Data ─────────────────────────────────────────────────
variable "subnet_data_db" {
  description = "CIDR subnet DB (Tier 3 — Stockage, CDE PCI-DSS)"
  type        = string
}

variable "subnet_data_pe" {
  description = "CIDR subnet Private Endpoints"
  type        = string
}

# ── CIDRs Subnets OnPrem ─────────────────────────────────────────────────────
variable "subnet_onprem_gateway" {
  description = "CIDR GatewaySubnet OnPrem (/27 minimum)"
  type        = string
}

variable "subnet_onprem_srv" {
  description = "CIDR subnet serveurs On-Premises"
  type        = string
}

# ── VMs ───────────────────────────────────────────────────────────────────────
variable "vm_admin_username" {
  description = "Utilisateur admin des VMs"
  type        = string
  sensitive   = true
}

variable "key_vault_name" {
  description = "Nom du Key Vault existant pour stocker les secrets SSH (ANSSI R14)"
  type        = string
  default     = "kv-core-security"
}

variable "key_vault_resource_group" {
  description = "Resource Group du Key Vault"
  type        = string
  default     = "RG-CORE-SECURITY"
}

variable "vm_size" {
  description = "Taille des VMs (FinOps : B1s = plus petit burstable)"
  type        = string
}

variable "auto_shutdown_time" {
  description = "Heure d'arrêt automatique des VMs (format HHMM, timezone Paris)"
  type        = string
}

# ── VPN / Hybridation ────────────────────────────────────────────────────────
variable "vpn_shared_key" {
  description = "Pre-Shared Key pour le tunnel IPsec (>32 caractères)"
  type        = string
  sensitive   = true
}

variable "hub_bgp_asn" {
  description = "ASN BGP de la Gateway Hub"
  type        = number
}

variable "onprem_bgp_asn" {
  description = "ASN BGP de la Gateway OnPrem simulée"
  type        = number
}

# ── Feature Flags (FinOps — déploiement progressif) ──────────────────────────
variable "deploy_vpn_gateways" {
  description = "Déploie les VPN Gateways (coûteuses ~0.38 €/h chacune)"
  type        = bool
}

variable "deploy_firewall" {
  description = "Déploie Azure Firewall Standard (coûteux ~1.30 €/h)"
  type        = bool
}

variable "deploy_waf" {
  description = "Déploie Application Gateway WAF v2 (~0.25 €/h)"
  type        = bool
}

variable "deploy_bastion" {
  description = "Déploie Azure Bastion Basic (~0.12 €/h)"
  type        = bool
}

variable "deploy_paas" {
  description = "Déploie les services PaaS (Storage, SQL, Private Endpoints)"
  type        = bool
}

variable "deploy_observability" {
  description = "Déploie la stack d'observabilité (Log Analytics, AMA, Alertes)"
  type        = bool
}

# ── Observabilité ─────────────────────────────────────────────────────────────
variable "alert_email" {
  description = "Email de l'équipe SecOps pour les alertes"
  type        = string
}

variable "law_retention_days" {
  description = "Rétention des logs dans Log Analytics (jours)"
  type        = number
}

# ── PaaS ──────────────────────────────────────────────────────────────────────
# ── PostgreSQL VM ────────────────────────────────────────────────────────────
variable "db_password" {
  description = "Mot de passe PostgreSQL (compte appuser sur vm-db) — Key Vault en prod"
  type        = string
  sensitive   = true
}

variable "sql_admin_login" {
  description = "Login admin Azure SQL Server"
  type        = string
  sensitive   = true
}

variable "sql_admin_password" {
  description = "Mot de passe admin Azure SQL Server (16+ caractères, complexe)"
  type        = string
  sensitive   = true
}
