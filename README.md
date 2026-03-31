# NETWORK-TP-FINAL-CLOUDSHIELD
Évaluation finale Mastère 1 — Module Conformité &amp; Protocoles Réseaux. Repo du projet « Cloud Shield » : audit ANSSI/PCI‑DSS, DAT Landing Zone Azure Secure by Design, code Terraform IaC et cahier de recette.


 Architecture Azure – TP CloudShield

## Contexte
Évaluation finale Mastère 1 – Module Conformité, Référentiels & Protocoles Réseaux.
Migration complète de l'infrastructure FinTech Global vers Microsoft Azure, suite à un incident de sécurité majeur et un audit ANSSI/PCI-DSS.

## Objectifs
- Réaliser la Gap Analysis de l'existant (5 pratiques non conformes A→E)
- Concevoir une Landing Zone Azure Secure by Design (Hub & Spoke, Zero Trust)
- Déployer l'infrastructure en IaC via Terraform
- Prouver techniquement 10 règles ANSSI via captures Azure
- Mettre en place une stack d'observabilité (SIEM) et répondre à un incident

## Architecture
Voir hiérarchie ci-dessus (section 4).

## Déploiement Terraform
### Structure des fichiers

terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│ ├── network/ # VNets, subnets, peerings, UDR
│ ├── security/ # NSG, ASG
│ ├── vpn/ # VNet Gateways, Local GW, connexion IPsec BGP
│ ├── compute/ # VMs Linux
│ ├── firewall/ # Azure Firewall + Policy
│ ├── bastion/ # Azure Bastion
│ ├── paas/ # Storage, SQL, Private Endpoints, DNS Privées
│ ├── waf/ # Application Gateway v2 WAF
│ └── observability/ # Log Analytics, NSG Flow Logs, AMA, DCR, Alerting

### Provider
- `azurerm` (version à préciser)
- Backend : [information manquante – Azure Storage ou local]

### Ressources principales
- `azurerm_resource_group`
- `azurerm_virtual_network`, `azurerm_subnet`
- `azurerm_virtual_network_peering`
- `azurerm_virtual_network_gateway`, `azurerm_local_network_gateway`, `azurerm_virtual_network_gateway_connection`
- `azurerm_network_security_group`, `azurerm_application_security_group`
- `azurerm_firewall`, `azurerm_firewall_policy`, `azurerm_route_table`
- `azurerm_bastion_host`
- `azurerm_linux_virtual_machine`, `azurerm_network_interface`
- `azurerm_storage_account`, `azurerm_mssql_server`, `azurerm_private_endpoint`
- `azurerm_private_dns_zone`, `azurerm_private_dns_zone_virtual_network_link`
- `azurerm_application_gateway`
- `azurerm_log_analytics_workspace`, `azurerm_network_watcher_flow_log`
- `azurerm_monitor_action_group`, `azurerm_monitor_scheduled_query_rules_alert`
- `azurerm_monitor_data_collection_rule`

## Sécurité
- Aucune VM exposée directement sur Internet (Azure Bastion obligatoire)
- Micro-segmentation par ASG (Zero Trust, pas d'adresses IP statiques dans les règles NSG)
- Tout le trafic sortant forcé via Azure Firewall (UDR 0.0.0.0/0)
- Services PaaS sans endpoint public (Private Endpoints + DNS Privées)
- Trafic entrant inspecté par WAF OWASP 3.2 (mode Prévention)
- Hybridation via IPsec IKEv2 + BGP (pas de GRE en clair)
- Traçabilité complète : NSG Flow Logs v2, Diagnostic Settings, Azure Monitor Agent (ANSSI Règle 36)
- Alerting automatique en cas d'anomalie volumétrique (>500 flux Denied / 5 min)

## Points ambigus
- [information manquante] : Contenu TP3 non extrait (PDF potentiellement image)
- [information manquante] : Contenu TP5 et TP5-Suite-Cloud non extrait de façon complète
- [information manquante] : Backend Terraform non spécifié dans les PDF
- [information manquante] : SKU exact Application Gateway (taille subnet SubnetWeb à vérifier)
- [information manquante] : Région de déploiement du Storage Account dédié logs (assumé `francecentral` par cohérence)
- [information manquante] : Version exacte du provider `azurerm` à utiliser

Architecture cible Azure (description textuelle)
L'architecture suit un modèle Hub & Spoke avec 4 VNets :

Hub (vnet-hub) : point central hébergeant le Firewall, le Bastion et la VPN Gateway

Spoke-Prod (vnet-spoke-prod) : 3 tiers applicatifs (Web, App, Mgmt)

Spoke-Data (vnet-spoke-data) : CDE PCI-DSS, SubnetDB isolé, Private Endpoints PaaS

OnPrem-Sim (vnet-onprem-sim) : simulation datacenter on-premise relié via tunnel IPsec IKEv2 BGP

Les Spokes communiquent exclusivement via le Hub. Tout trafic sortant est forcé vers Azure Firewall via UDR. L'accès SSH/RDP aux VMs est uniquement possible via Azure Bastion. Les services PaaS (Storage, SQL) sont exposés exclusivement en privé via Private Endpoints et DNS Privées. L'Application Gateway v2 avec WAF intercepte tout le trafic entrant.

Hiérarchie des composants

rg-zerotrust-prod (francecentral)
├── RÉSEAU
│   ├── vnet-hub (10.0.0.0/16)
│   │   ├── GatewaySubnet (10.0.6.0/27)
│   │   ├── AzureBastionSubnet (10.0.5.0/26)
│   │   ├── AzureFirewallSubnet (10.0.0.0/26)
│   │   └── SubnetMgmt (10.0.4.0/24)
│   ├── vnet-spoke-prod (10.1.0.0/16)
│   │   ├── SubnetWeb (10.1.1.0/24)
│   │   ├── SubnetApp (10.1.2.0/24)
│   │   └── SubnetMgmt (10.1.3.0/24)
│   ├── vnet-spoke-data (10.2.0.0/16)
│   │   ├── SubnetDB (10.2.1.0/24)
│   │   └── SubnetMgmt (10.2.2.0/24)
│   └── vnet-onprem-sim (10.10.0.0/16)
│       ├── GatewaySubnet (10.10.6.0/27)
│       └── SubnetSrv (10.10.1.0/24)
├── PEERINGS
│   ├── Hub ↔ Spoke-Prod (Gateway Transit ON)
│   └── Hub ↔ Spoke-Data (Gateway Transit ON)
├── SÉCURITÉ
│   ├── ASG : asg-web, asg-app, asg-db, asg-bastion
│   ├── NSG nsg-web (SubnetWeb)
│   ├── NSG nsg-db (SubnetDB)
│   └── NSG AzureBastionSubnet
├── COMPUTE
│   ├── vm-web → SubnetWeb, asg-web (sans IP publique)
│   ├── vm-app → SubnetApp, asg-app (sans IP publique)
│   ├── vm-db → SubnetDB, asg-db (sans IP publique)
│   └── vm-onprem → SubnetSrv
├── GATEWAY
│   ├── VPN Gateway Hub (VpnGw1, AS 65001)
│   └── VPN Gateway OnPrem (VpnGw1, AS 65002)
│       └── Connexion IPsec IKEv2 BGP
├── PARE-FEU & ROUTAGE
│   ├── Azure Firewall Standard (Hub)
│   ├── Firewall Policy (règle TCP 5432 + FQDN)
│   └── UDR rt-spoke-to-hub → 0.0.0.0/0 → Firewall
├── ACCÈS SÉCURISÉ
│   └── Azure Bastion (Hub)
├── PAAS SÉCURISÉ
│   ├── Storage Account (accès public OFF)
│   │   └── Private Endpoint Blob (SubnetDB)
│   ├── Azure SQL Server (accès public OFF)
│   │   └── Private Endpoint SQL (SubnetDB)
│   ├── Zone DNS Privée : privatelink.blob.core.windows.net
│   └── Zone DNS Privée : privatelink.database.windows.net
├── ENTRÉE WEB
│   └── Application Gateway v2 + WAF (OWASP 3.2, mode Prévention)
└── OBSERVABILITÉ (tout IaC)
    ├── Log Analytics Workspace
    ├── Storage Account (logs NSG Flow Logs)
    ├── NSG Flow Logs v2 (nsg-web, nsg-db)
    ├── Diagnostic Settings (Firewall, Bastion, VPN GW)
    ├── Azure Monitor Agent (vm-web, vm-app, vm-db)
    ├── Data Collection Rule (Syslog)
    ├── Action Group AG-SecOps (email)
    └── Alert Rule (>500 Denied / 5 min)
    
