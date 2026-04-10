# NETWORK-TP-FINAL — Cloud Shield

## Documentation en ligne

👉 https://ynovops-infragroup.github.io/NETWORK-TP-FINAL-CLOUDSHIELD/

**Statut : IaC Prêt** · 16 fichiers Terraform · francecentral · 31 mars 2026

> Infrastructure as Code (Terraform) déployant une **Landing Zone Azure Secure by Design** pour la société FinTech Global, suite à un incident cyber critique. Architecture Hub & Spoke, Zero Trust, conformité ANSSI. Évaluation finale Mastère 1 — Module Conformité, Référentiels & Protocoles Réseaux.

---

## Contexte

| Champ               | Valeur                                                      |
| ------------------- | ----------------------------------------------------------- |
| Cours               | Cloud & Infrastructure Azure — Ynov Mastère 1               |
| Projet              | TP Final · Cloud Shield                                     |
| Organisation GitHub | [YnovOps-InfraGroup](https://github.com/YnovOps-InfraGroup) |
| Région              | `francecentral`                                             |
| Backend Terraform   | Storage Account distant — container `tfstate`               |

---

## Architecture déployée

```
Internet
    │
    ▼
┌───────────────────────────────────────────────────────────────────┐
│  vnet-hub (10.0.0.0/16)                                           │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │  WAF v2      │  │ Azure        │  │  VPN Gateway │             │
│  │  (AppGW)     │  │ Firewall     │  │  (IPsec/BGP) │             │
│  │  OWASP 3.2   │  │  Standard    │  │  ← OnPrem    │             │
│  │  Prévention  │  │  UDR 0/0     │  └──────────────┘             │
│  └──────┬───────┘  └──────┬───────┘                               │
│         │ (inspection)    │ (egress forcé)  ┌─────────────────┐   │
│         │                 │                 │  Azure Bastion  │   │
│         │                 │                 │  (admin seul)   │   │
│         │                 │                 └────────┬────────┘   │
└─────────┼─────────────────┼──────────────────────────┼────────────┘
          │ peering         │ peering                  │ peering
    ┌─────▼──────────────────▼──────────────────────────▼──────┐
    │                                                           │
┌───▼──────────────────────┐  ┌────────────────────────────────▼──┐
│  vnet-spoke-prod         │  │  vnet-spoke-data                  │
│  (10.1.0.0/16)           │  │  (10.2.0.0/16)                    │
│                          │  │                                   │
│  ┌──────────┐            │  │  ┌──────────┐  ┌──────────────┐   │
│  │ vm-web   │ asg-web    │  │  │ vm-db    │  │  SQL Server  │   │
│  │ (Ubuntu) │            │  │  │ (Ubuntu) │  │  Private EP  │   │
│  └──────────┘            │  │  └──────────┘  └──────────────┘   │
│  ┌──────────┐            │  │  ┌────────────────────────────┐   │
│  │ vm-app   │ asg-app    │  │  │  Storage Account           │   │
│  │ (Ubuntu) │            │  │  │  Private Endpoint          │   │
│  └──────────┘            │  │  └────────────────────────────┘   │
│  NSG micro-segmenté      │  │  NSG: Web→App→DB uniquement       │
│  ASG (pas d'IP statiques)│  │  Aucun accès Internet direct      │
└──────────────────────────┘  └───────────────────────────────────┘
          │
┌─────────▼────────────────┐
│  vnet-onprem-sim         │
│  (10.10.0.0/16)          │
│  Simulation On-Premises  │
│  VPN IKEv2 + BGP         │
└──────────────────────────┘
```

**Backend Terraform :** Storage Account distant (Infra-core-3sr)
**State key :** `network-tp-final-cloudshield/terraform.tfstate`

---

## Livrables

| #   | Livrable                                | Fichier                                                                |
| --- | --------------------------------------- | ---------------------------------------------------------------------- |
| 1   | Matrice d'Audit ANSSI (5 pratiques A→E) | [docs/Livrables/LIVRABLE-1-MATRICE-AUDIT.md](docs/Livrables/LIVRABLE-1-MATRICE-AUDIT.md) |
| 2   | DAT — Document d'Architecture Technique | [docs/Livrables/LIVRABLE-2-DAT.md](docs/Livrables/LIVRABLE-2-DAT.md)                     |
| 3   | Infrastructure as Code Terraform        | [terraform/](terraform/)                                                                 |
| 4   | Cahier de Recette — 10 preuves ANSSI    | [docs/Livrables/LIVRABLE-4-CAHIER-RECETTE.md](docs/Livrables/LIVRABLE-4-CAHIER-RECETTE.md) |

---

## Ressources déployées

### Réseau

| Ressource            | Nom                                                                                                       | Notes                           |
| -------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------- |
| Resource Groups (1)  | `rg-cloudshield-prod`                                                                                     | PoC - pérennité nécessite 4 RGs séparés (hub, prod, data, onprem) |
| Virtual Networks (4) | `vnet-hub`, `vnet-spoke-prod`, `vnet-spoke-data`, `vnet-onprem-sim`                                       | Hub & Spoke                     |
| Peerings (4)         | Hub↔Prod, Hub↔Data                                                                                        | Bidirectionnels + allow_gateway |
| Subnets (11)         | AzureFirewallSubnet, GatewaySubnet, AzureBastionSubnet, snet-waf, snet-web, snet-app, snet-db, snet-pe, … | Micro-segmentés                 |
| Route Tables (3)     | `rt-spoke-prod`, `rt-spoke-data`, `rt-onprem-sim`                                                         | UDR 0.0.0.0/0 → Firewall        |

### Sécurité

| Ressource                  | Nom                                                      | Notes                          |
| -------------------------- | -------------------------------------------------------- | ------------------------------ |
| Azure Firewall Premium     | `fw-cloudshield-hub`                                     | Policy + règles App/Net/DNAT   |
| Application Gateway v2 WAF | `waf-cloudshield-hub`                                    | OWASP 3.2, mode Prévention     |
| Azure Bastion Standard     | `bastion-cloudshield-hub`                                | Accès admin uniquement         |
| NSG (5)                    | `nsg-bastion`, `nsg-waf`, `nsg-web`, `nsg-app`, `nsg-db` | Deny-all implicite             |
| ASG (3)                    | `asg-web`, `asg-app`, `asg-db`                           | Zero Trust, pas d'IP statiques |

### Compute

| Ressource | Nom              | SKU          | Notes                 |
| --------- | ---------------- | ------------ | --------------------- |
| VM Web    | `vm-web-prod-01` | Standard_B1s | Ubuntu 22.04, asg-web |
| VM App    | `vm-app-prod-01` | Standard_B1s | Ubuntu 22.04, asg-app |
| VM DB     | `vm-db-prod-01`  | Standard_B1s | Ubuntu 22.04, asg-db  |

### PaaS & Connexions

| Ressource             | Nom                                                                     | Notes                                   |
| --------------------- | ----------------------------------------------------------------------- | --------------------------------------- |
| SQL Server + DB       | `sql-cloudshield-data`                                                  | Pas d'endpoint public, Private Endpoint |
| Storage Account       | `stcloudshielddata`                                                     | Private Endpoint, TLS 1.2               |
| Private DNS Zones (2) | `privatelink.database.windows.net`, `privatelink.blob.core.windows.net` | DNS interne fonctionnel                 |
| VPN Gateway           | `vpng-cloudshield-hub`                                                  | VpnGw1, IKEv2, BGP AS 65001             |
| Local Network Gateway | `lgw-onprem-01`                                                         | Simulation on-premises                  |

### Observabilité

| Ressource               | Notes                                          |
| ----------------------- | ---------------------------------------------- |
| Log Analytics Workspace | `law-cloudshield-01`, PerGB2018, 30j rétention |
| NSG Flow Logs v2 × 5    | Traffic Analytics 10min → LAW                  |
| Diagnostic Settings     | Firewall, WAF, Bastion → LAW                   |
| AMA + DCR               | Sur toutes les VMs                             |
| Action Groups + Alertes | Email on anomalie volumétrique                 |

---

## Plan d'adressage IP (IPAM)

| VNet / Subnet         | CIDR           | Rôle                           |
| --------------------- | -------------- | ------------------------------ |
| `vnet-hub`            | `10.0.0.0/16`  | Hub central                    |
| `AzureFirewallSubnet` | `10.0.1.0/26`  | Azure Firewall (nom imposé)    |
| `AzureBastionSubnet`  | `10.0.2.0/26`  | Azure Bastion (nom imposé)     |
| `GatewaySubnet`       | `10.0.3.0/27`  | VPN Gateway (nom imposé)       |
| `vnet-spoke-prod`     | `10.1.0.0/16`  | Spoke Production               |
| `snet-prod-web`       | `10.1.1.0/24`  | Tier 1 — Web (Flask)           |
| `snet-prod-app`       | `10.1.2.0/24`  | Tier 2 — App (logique métier)  |
| `snet-prod-waf`       | `10.1.3.0/24`  | Application Gateway WAF v2     |
| `vnet-spoke-data`     | `10.2.0.0/16`  | Spoke Data (CDE PCI-DSS)       |
| `snet-data-db`        | `10.2.1.0/24`  | Tier 3 — Database (PostgreSQL) |
| `snet-data-pe`        | `10.2.2.0/24`  | Private Endpoints (Blob, SQL)  |
| `vnet-onprem-sim`     | `10.10.0.0/16` | Simulation On-Premises (Lyon)  |
| `GatewaySubnet`       | `10.10.0.0/27` | VPN Gateway OnPrem             |
| `snet-onprem-srv`     | `10.10.1.0/24` | Serveurs simulés On-Prem       |

---

## Phases du TP couvertes

| Phase | Description                                     | Statut |
| ----- | ----------------------------------------------- | ------ |
| 1     | Matrice d'Audit — Gap Analysis ANSSI (A→E)      | ✅ L1  |
| 2     | Plan d'adressage IP + HLD Architecture          | ✅ L2  |
| 3     | Resource Groups + VNets + Peerings              | ✅ IaC |
| 4     | NSG micro-segmentés + ASG Zero Trust            | ✅ IaC |
| 5     | Azure Firewall Premium + Politique + UDR        | ✅ IaC |
| 6     | WAF Application Gateway v2 OWASP 3.2            | ✅ IaC |
| 7     | Azure Bastion Standard                          | ✅ IaC |
| 8     | VMs 3-tiers (Web / App / DB)                    | ✅ IaC |
| 9     | VPN Gateway IPsec/IKEv2 + BGP                   | ✅ IaC |
| 10    | PaaS sécurisé — Private Endpoints + DNS         | ✅ IaC |
| 11    | Observabilité — LAW + Flow Logs + AMA + Alertes | ✅ IaC |
| 12    | Cahier de Recette — 10 preuves ANSSI            | ✅ L4  |

---

## Déploiement

### 1 — Prérequis

```bash
terraform >= 1.11.0
az login && az account set --subscription <SUBSCRIPTION_ID>
```

### 2 — Préparer les variables

```bash
cd terraform/
cp terraform.tfvars.template terraform.tfvars
# Remplir : vm_ssh_public_key, alert_email
```

| Variable              | Obligatoire | Défaut                        |
| --------------------- | ----------- | ----------------------------- |
| `subscription_id`     | ✅          | —                             |
| `vm_ssh_public_key`   | ✅          | —                             |
| `alert_email`         | ✅          | —                             |
| `deploy_vpn_gateways` | ❌          | `false` (économies ~0,76 €/h) |

### 3 — Déployer

```bash
terraform init
terraform validate
terraform plan -out=cloudshield.tfplan
terraform apply cloudshield.tfplan
```

> **Durée estimée :** ~25-35 min (Azure Firewall + Bastion + WAF)

### 4 — Détruire (FinOps — destroy quotidien)

```bash
terraform destroy -auto-approve
```

---

## Sécurité

- Aucune VM exposée directement sur Internet — **Azure Bastion obligatoire**
- Micro-segmentation par **ASG** (Zero Trust, zéro IP statique dans les règles NSG)
- Tout le trafic sortant forcé via **Azure Firewall** (UDR `0.0.0.0/0`)
- Services PaaS sans endpoint public — **Private Endpoints + DNS Privées**
- Trafic entrant inspecté par **WAF OWASP 3.2** (mode Prévention)
- Hybridation via **IPsec IKEv2 + BGP** (chiffrement bout en bout)
- Traçabilité complète : NSG Flow Logs v2, Diagnostic Settings, AMA (ANSSI Règle 36)
- Alerting automatique en cas d'anomalie volumétrique (>500 flux Denied / 5 min)

---

## FinOps

| Ressource                   | Coût estimé/h | Coût/j        |
| --------------------------- | ------------- | ------------- |
| Azure Firewall Premium      | ~0,98 €/h     | ~23,5 €/j     |
| Application Gateway WAF v2  | ~0,35 €/h     | ~8,4 €/j      |
| Azure Bastion Standard      | ~0,19 €/h     | ~4,6 €/j      |
| VMs ×3 Standard_B2s         | ~0,12 €/h     | ~2,8 €/j      |
| SQL + Storage               | ~0,06 €/h     | ~1,4 €/j      |
| **Total Phase 1**           | **~1,70 €/h** | **~40,7 €/j** |
| VPN Gateways ×2 (optionnel) | +0,76 €/h     | +18,2 €/j     |

> Destroy quotidien recommandé pour limiter les coûts hors démo.

---

## Auteur

**Myscile Gregory** — Mastère 1 Cloud & Infrastructure · Ynov · 2025-2026
