# ============================================================
# VARIABLES — Cloud Shield Landing Zone
# Valeurs sensibles dans terraform.tfvars (gitignorée)
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
  default     = "France Central"
}

variable "project_name" {
  description = "Nom du projet (utilisé dans le nommage des ressources)"
  type        = string
  default     = "cloudshield"
}

variable "environment" {
  description = "Environnement (prod, dev, poc)"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Tags communs à toutes les ressources"
  type        = map(string)
  default = {
    projet     = "TP-Final"
    managed_by = "terraform"
    owner      = "Myscile-gregory"
  }
}

# ── CIDRs VNets ──────────────────────────────────────────────────────────────
variable "vnet_hub_cidr" {
  description = "CIDR du VNet Hub"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vnet_spoke_prod_cidr" {
  description = "CIDR du VNet Spoke Production"
  type        = string
  default     = "10.1.0.0/16"
}

variable "vnet_spoke_data_cidr" {
  description = "CIDR du VNet Spoke Data (CDE PCI-DSS)"
  type        = string
  default     = "10.2.0.0/16"
}

variable "vnet_onprem_cidr" {
  description = "CIDR du VNet simulant le site On-Premises (Lyon)"
  type        = string
  default     = "10.10.0.0/16"
}

# ── CIDRs Subnets Hub ────────────────────────────────────────────────────────
variable "subnet_hub_firewall" {
  description = "CIDR AzureFirewallSubnet (/26 minimum obligatoire)"
  type        = string
  default     = "10.0.1.0/26"
}

variable "subnet_hub_bastion" {
  description = "CIDR AzureBastionSubnet (/26 minimum obligatoire)"
  type        = string
  default     = "10.0.2.0/26"
}

variable "subnet_hub_gateway" {
  description = "CIDR GatewaySubnet (/27 minimum)"
  type        = string
  default     = "10.0.3.0/27"
}

# ── CIDRs Subnets Spoke-Prod ─────────────────────────────────────────────────
variable "subnet_prod_web" {
  description = "CIDR subnet Web (Tier 1 — Présentation)"
  type        = string
  default     = "10.1.1.0/24"
}

variable "subnet_prod_app" {
  description = "CIDR subnet App (Tier 2 — Traitement)"
  type        = string
  default     = "10.1.2.0/24"
}

variable "subnet_prod_waf" {
  description = "CIDR subnet WAF / Application Gateway"
  type        = string
  default     = "10.1.3.0/24"
}

# ── CIDRs Subnets Spoke-Data ─────────────────────────────────────────────────
variable "subnet_data_db" {
  description = "CIDR subnet DB (Tier 3 — Stockage, CDE PCI-DSS)"
  type        = string
  default     = "10.2.1.0/24"
}

variable "subnet_data_pe" {
  description = "CIDR subnet Private Endpoints"
  type        = string
  default     = "10.2.2.0/24"
}

# ── CIDRs Subnets OnPrem ─────────────────────────────────────────────────────
variable "subnet_onprem_gateway" {
  description = "CIDR GatewaySubnet OnPrem (/27 minimum)"
  type        = string
  default     = "10.10.0.0/27"
}

variable "subnet_onprem_srv" {
  description = "CIDR subnet serveurs On-Premises"
  type        = string
  default     = "10.10.1.0/24"
}

# ── VMs ───────────────────────────────────────────────────────────────────────
variable "vm_admin_username" {
  description = "Utilisateur admin des VMs"
  type        = string
  default     = "azureuser"
}

variable "vm_ssh_public_key" {
  description = "Clé SSH publique Ed25519 pour l'authentification aux VMs"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Taille des VMs (FinOps : B1s = plus petit burstable)"
  type        = string
  default     = "Standard_B1s"
}

# ── VPN / Hybridation ────────────────────────────────────────────────────────
variable "vpn_shared_key" {
  description = "Pre-Shared Key pour le tunnel IPsec (>32 caractères)"
  type        = string
  sensitive   = true
  default     = "***VPN_KEY_REMOVED***"
}

variable "hub_bgp_asn" {
  description = "ASN BGP de la Gateway Hub"
  type        = number
  default     = 65001
}

variable "onprem_bgp_asn" {
  description = "ASN BGP de la Gateway OnPrem simulée"
  type        = number
  default     = 65002
}

# ── Feature Flags (FinOps — déploiement progressif) ──────────────────────────
variable "deploy_vpn_gateways" {
  description = "Déploie les VPN Gateways (coûteuses ~0.38€/h chacune)"
  type        = bool
  default     = false
}

variable "deploy_firewall" {
  description = "Déploie Azure Firewall Standard (coûteux ~1.30€/h)"
  type        = bool
  default     = true
}

variable "deploy_waf" {
  description = "Déploie Application Gateway WAF v2"
  type        = bool
  default     = true
}

variable "deploy_bastion" {
  description = "Déploie Azure Bastion"
  type        = bool
  default     = true
}

variable "deploy_paas" {
  description = "Déploie les services PaaS (Storage, SQL, Private Endpoints)"
  type        = bool
  default     = true
}

variable "deploy_observability" {
  description = "Déploie la stack d'observabilité (Log Analytics, AMA, Alertes)"
  type        = bool
  default     = true
}

# ── Observabilité ─────────────────────────────────────────────────────────────
variable "alert_email" {
  description = "Email de l'équipe SecOps pour les alertes"
  type        = string
  default     = "secops@fintechglobal.local"
}

variable "law_retention_days" {
  description = "Rétention des logs dans Log Analytics (jours)"
  type        = number
  default     = 30
}

# ── PaaS ──────────────────────────────────────────────────────────────────────
variable "sql_admin_login" {
  description = "Login admin Azure SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "Mot de passe admin Azure SQL Server (16+ caractères, complexe)"
  type        = string
  sensitive   = true
  default     = "***SQL_PASSWORD_REMOVED***"
}
