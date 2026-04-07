# ============================================================
# variables.auto.tfvars — Cloud Shield Landing Zone
# Valeurs NON-SENSIBLES — commitable sur Git
# ============================================================

# ── Région & Naming ──────────────────────────────────────────
location     = "France Central"
project_name = "cloudshield"
environment  = "prod"

# ── VMs ──────────────────────────────────────────────────────
vm_size            = "Standard_B1s"
auto_shutdown_time = "2000" # 20h00 Paris — auto-shutdown FinOps

# ── VPN BGP ASNs ─────────────────────────────────────────────
hub_bgp_asn    = 65001
onprem_bgp_asn = 65002

# ── Observabilité ─────────────────────────────────────────────
alert_email        = "secops@fintechglobal.local"
law_retention_days = 30

# ── Plan d'adressage IP (IPAM) ───────────────────────────────
# VNets
vnet_hub_cidr        = "10.0.0.0/16"
vnet_spoke_prod_cidr = "10.1.0.0/16"
vnet_spoke_data_cidr = "10.2.0.0/16"
vnet_onprem_cidr     = "10.10.0.0/16"

# Subnets Hub
subnet_hub_firewall = "10.0.1.0/26" # AzureFirewallSubnet (/26 minimum)
subnet_hub_bastion  = "10.0.2.0/26" # AzureBastionSubnet  (/26 minimum)
subnet_hub_gateway  = "10.0.3.0/27" # GatewaySubnet       (/27 minimum)

# Subnets Spoke-Prod
subnet_prod_web = "10.1.1.0/24"
subnet_prod_app = "10.1.2.0/24"
subnet_prod_waf = "10.1.3.0/24"

# Subnets Spoke-Data
subnet_data_db = "10.2.1.0/24"
subnet_data_pe = "10.2.2.0/24"

# Subnets OnPrem (simulé)
subnet_onprem_gateway = "10.10.0.0/27"
subnet_onprem_srv     = "10.10.1.0/24"

# ══════════════════════════════════════════════════════════════
# FEATURE FLAGS — Déploiement progressif (FinOps)
# false = non déployé | true = déployé
# ══════════════════════════════════════════════════════════════
deploy_firewall      = false # Azure Firewall Standard  ~30 €/j  ← Phase 2
deploy_bastion       = false # Azure Bastion Basic      ~4,6 €/j ← Phase 2
deploy_waf           = false # App Gateway WAF v2       ~11 €/j  ← Phase 2
deploy_vpn_gateways  = false # VPN Gateways x2          ~18 €/j  ← Phase 3
deploy_paas          = true  # SQL + Storage + PE       ~0,7 €/j ✅
deploy_observability = true  # Log Analytics + Alertes  ~0 €/j   ✅

# ── PostgreSQL VM ────────────────────────────────────────────
# TODO: remplacer par une référence Key Vault en production
db_password = "ChangeMe123!" # Lab only — changer avant mise en prod
