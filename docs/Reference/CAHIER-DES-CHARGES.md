# <i class="fa-solid fa-file-contract"></i> Cahier des Charges — Projet Cloud Shield

## Landing Zone Azure "Secure by Design" pour FinTech Global

<div style="margin-bottom:1.5em">
  <img src="https://img.shields.io/badge/Version-1.0-0078D4?style=flat-square" alt="v1.0" />
  <img src="https://img.shields.io/badge/Classification-Confidentiel-FF4500?style=flat-square" alt="Confidentiel" />
  <img src="https://img.shields.io/badge/Soutenance-14_avril_2026-3fb950?style=flat-square" alt="Soutenance" />
  <img src="https://img.shields.io/badge/Client-FinTech_Global-8b949e?style=flat-square" alt="Client" />
</div>

| Champ              | Valeur                                         |
| ------------------ | ---------------------------------------------- |
| **Client**         | FinTech Global — Transactions B2B              |
| **Prestataire**    | Cabinet Expert Cloud, Réseaux & Sécurité Azure |
| **Date**           | 31 mars 2026                                   |
| **Version**        | 1.0                                            |
| **Classification** | Confidentiel                                   |
| **Soutenance**     | 14 avril 2026                                  |

---

## 1. Contexte & Enjeux

### 1.1 Situation initiale

FinTech Global, société spécialisée dans les transactions B2B, a subi un **incident cyber majeur** :

- **Exfiltration** de données bancaires clients
- **Ransomware** déployé sur l'ensemble du SI
- **4 jours d'arrêt total** de la production
- **Audit flash** ordonné par la Banque de France

### 1.2 Causes racines identifiées (5 pratiques défaillantes)

| Pratique | Description                                                                          | Criticité   |
| -------- | ------------------------------------------------------------------------------------ | ----------- |
| **A**    | Réseau plat 10.0.0.0/8 — aucune segmentation (Wi-Fi invité + BDD sur le même switch) | 🔴 CRITIQUE |
| **B**    | IP publiques sur les BDD, SSH root, mot de passe `P@ssword123`                       | 🔴 CRITIQUE |
| **C**    | Tunnel GRE en clair entre Lyon et le siège (aucun chiffrement)                       | 🔴 CRITIQUE |
| **D**    | Logs en RAM uniquement — aucune journalisation centralisée                           | 🔴 CRITIQUE |
| **E**    | Accès Internet total depuis la production (le ransomware a contacté son C2)          | 🔴 CRITIQUE |

### 1.3 Mandat

Construire une **architecture Cloud Azure complète**, sécurisée, conforme au **Guide d'hygiène ANSSI** (42 règles), et prouvable techniquement.

---

## 2. Objectifs du Projet

### 2.1 Objectifs fonctionnels

| #    | Objectif                                                  | Mesure de succès                                          |
| ---- | --------------------------------------------------------- | --------------------------------------------------------- |
| OF-1 | Migrer l'intégralité du SI vers Azure                     | 100% des workloads opérationnels dans Azure               |
| OF-2 | Héberger une application 3-tiers (Web → App → DB)         | Application accessible via WAF, flux fonctionnels prouvés |
| OF-3 | Maintenir la connectivité avec le site On-Premises (Lyon) | Tunnel VPN IPsec opérationnel + routes BGP échangées      |
| OF-4 | Centraliser la supervision et la traçabilité              | SIEM opérationnel avec alertes automatiques               |

### 2.2 Objectifs de sécurité

| #    | Objectif                                   | Référentiel         | Mesure de succès                                                |
| ---- | ------------------------------------------ | ------------------- | --------------------------------------------------------------- |
| OS-1 | Segmentation réseau stricte                | ANSSI R19           | 4 VNets isolés, aucun flux non autorisé                         |
| OS-2 | Zero Trust — deny-all par défaut           | ANSSI R19, R22      | Micro-segmentation NSG/ASG, tout trafic interdit sauf whitelist |
| OS-3 | Inspection centralisée du trafic           | ANSSI R23           | Azure Firewall sur tout le trafic N/S et E/W                    |
| OS-4 | Chiffrement des communications inter-sites | ANSSI R25, R21      | IPsec IKEv2, AES-256-GCM, PFS                                   |
| OS-5 | Administration sécurisée sans exposition   | ANSSI R13, R22, R28 | Azure Bastion, clés SSH, aucune IP publique sur les VMs         |
| OS-6 | Sanctuarisation du PaaS                    | ANSSI R9, R23       | Private Endpoints, aucun endpoint public                        |
| OS-7 | Journalisation centralisée complète        | ANSSI R36, R37, R40 | Log Analytics + NSG Flow Logs + AMA + alertes                   |
| OS-8 | Protection contre les attaques web         | OWASP Top 10        | WAF OWASP 3.2, mode Prévention                                  |

### 2.3 Objectifs opérationnels

| #    | Objectif                         | Mesure de succès                                               |
| ---- | -------------------------------- | -------------------------------------------------------------- |
| OO-1 | Déploiement 100% IaC (Terraform) | `terraform apply` reproductible, `terraform destroy` quotidien |
| OO-2 | Optimisation des coûts (FinOps)  | Budget < 200 € pour 2 semaines                                 |
| OO-3 | Documentation complète           | 4 livrables produits et cohérents                              |
| OO-4 | Scalabilité                      | Ajout de spokes QA/PreProd sans redéployer le Hub              |

---

## 3. Périmètre

### 3.1 In-Scope

| Domaine             | Détail                                                               |
| ------------------- | -------------------------------------------------------------------- |
| **Réseau**          | 4 VNets (Hub, Spoke-Prod, Spoke-Data, OnPrem-Sim), Peerings, UDR     |
| **Sécurité réseau** | Azure Firewall Standard, WAF v2 OWASP 3.2, NSG, ASG                  |
| **Compute**         | 4 VMs Linux Ubuntu 22.04 (B1s) sans IP publique                      |
| **Hybridation**     | VPN IPsec IKEv2 + BGP (AS 65001/65002)                               |
| **PaaS**            | Storage Account + Azure SQL via Private Endpoints + DNS privées      |
| **Admin**           | Azure Bastion Basic — SSH/RDP tunnelé                                |
| **Observabilité**   | Log Analytics, NSG Flow Logs v2, AMA, DCR, Action Group, Alert Rules |
| **IaC**             | Terraform AzureRM 4.x, 16 fichiers, backend remote                   |

### 3.2 Out-of-Scope

| Exclusion                        | Raison                                            |
| -------------------------------- | ------------------------------------------------- |
| Azure Sentinel (SIEM avancé)     | Coût disproportionné pour un PoC                  |
| Azure DDoS Protection Standard   | ~2 676 €/mois — hors budget étudiant              |
| Azure AD P2 / Conditional Access | Hors périmètre réseau pur                         |
| Backup / Disaster Recovery       | Non exigé par le sujet                            |
| CI/CD Pipeline (Azure DevOps)    | Le déploiement se fait en local (terraform apply) |

### 3.3 Contraintes

| Contrainte             | Détail                                            |
| ---------------------- | ------------------------------------------------- |
| **Subscription Azure** | `SUBSCRIPTION_ID_REMOVED`                         |
| **Tenant**             | `TENANT_ID_REMOVED`                               |
| **Région**             | France Central                                    |
| **Aucune dépendance**  | Interdit d'utiliser des ressources du RG-Ynov-VPN |
| **Budget**             | Crédits Azure étudiants (~200 €)                  |
| **Deadline**           | 14 avril 2026 — soutenance orale                  |

---

## 4. Architecture Technique

### 4.1 Modèle : Hub & Spoke

```
                          INTERNET
                     ┌───────┴───────┐
                     │               │
                ┌────▼────┐    ┌────▼─────┐
                │   WAF   │    │  VPN GW  │
                │ AppGW v2│    │  Hub     │
                └────┬────┘    └────┬─────┘
                     │              │
    ┌────────────────┼──────────────┼────────────────┐
    │            HUB VNET (10.0.0.0/16)              │
    │                                                │
    │  Azure Firewall ◄── inspecte tout le trafic    │
    │  Azure Bastion  ◄── admin SSH sécurisé         │
    │  GatewaySubnet  ◄── VPN IPsec/BGP              │
    └───┬─────────────────────┬──────────────────┬───┘
        │                     │                  │
   ┌────▼──────┐       ┌─────▼──────┐    ┌─────▼──────┐
   │SPOKE-PROD │       │SPOKE-DATA  │    │ONPREM-SIM  │
   │10.1.0.0/16│       │10.2.0.0/16 │    │10.10.0.0/16│
   │           │       │            │    │            │
   │ vm-web    │       │ vm-db      │    │ vm-onprem  │
   │ vm-app    │       │ PE-Storage │    │            │
   │ WAF snet  │       │ PE-SQL     │    │            │
   └───────────┘       └────────────┘    └────────────┘
```

### 4.2 Plan d'adressage IP (IPAM)

| VNet                 | CIDR         | Rôle                                   |
| -------------------- | ------------ | -------------------------------------- |
| vnet-hub-cloudshield | 10.0.0.0/16  | Hub — sécurité, egress, hybridation    |
| vnet-spoke-prod      | 10.1.0.0/16  | Production — application 3-tiers       |
| vnet-spoke-data      | 10.2.0.0/16  | Données — CDE (DB + Private Endpoints) |
| vnet-onprem-sim      | 10.10.0.0/16 | Simulation On-Premises (Lyon)          |
| _Réservé_            | 10.3.0.0/16  | Pre-Prod (scalabilité future)          |
| _Réservé_            | 10.4.0.0/16  | QA (scalabilité future)                |

#### Détail des Subnets

| VNet       | Subnet              | CIDR         | Usage                                 |
| ---------- | ------------------- | ------------ | ------------------------------------- |
| Hub        | AzureFirewallSubnet | 10.0.1.0/26  | Azure Firewall (nom imposé)           |
| Hub        | AzureBastionSubnet  | 10.0.2.0/26  | Azure Bastion (nom imposé)            |
| Hub        | GatewaySubnet       | 10.0.3.0/27  | VPN Gateways (nom imposé)             |
| Spoke-Prod | snet-prod-web       | 10.1.1.0/24  | Tier 1 — Web (Flask)                  |
| Spoke-Prod | snet-prod-app       | 10.1.2.0/24  | Tier 2 — Application (logique métier) |
| Spoke-Prod | snet-prod-waf       | 10.1.3.0/24  | Application Gateway WAF v2            |
| Spoke-Data | snet-data-db        | 10.2.1.0/24  | Tier 3 — Database (PostgreSQL)        |
| Spoke-Data | snet-data-pe        | 10.2.2.0/24  | Private Endpoints (Storage, SQL)      |
| OnPrem     | GatewaySubnet       | 10.10.0.0/27 | VPN Gateway On-Premises               |
| OnPrem     | snet-onprem-srv     | 10.10.1.0/24 | Serveurs simulés On-Prem              |

### 4.3 Matrice de flux autorisés

> **Principe : Deny-All par défaut — tout flux non listé ici est interdit.**

| #   | Source             | Destination    | Proto | Port      | Contrôle               |
| --- | ------------------ | -------------- | ----- | --------- | ---------------------- |
| 1   | Internet           | AppGW WAF      | TCP   | 443       | WAF OWASP 3.2          |
| 2   | AppGW WAF          | asg-web        | TCP   | 80        | NSG                    |
| 3   | asg-web            | asg-app        | TCP   | 8080      | NSG + FW               |
| 4   | asg-app            | asg-db         | TCP   | 5432      | NSG + FW (cross-spoke) |
| 5   | Bastion            | Toutes VMs     | TCP   | 22        | Azure Bastion          |
| 6   | Tout spoke         | Azure Firewall | \*    | \*        | UDR forced tunneling   |
| 7   | Azure Firewall     | Ubuntu repos   | TCP   | 80, 443   | FQDN rule              |
| 8   | Azure Firewall     | Azure Monitor  | TCP   | 443       | Service tag            |
| 9   | Hub GW ↔ OnPrem GW | IPsec          | UDP   | 500, 4500 | VPN Gateway            |
| 10  | snet-data-db       | PE Storage/SQL | TCP   | 443, 1433 | Private Endpoint       |

### 4.4 Flux interdits (démonstration soutenance)

| Source                  | Destination | Preuve                     |
| ----------------------- | ----------- | -------------------------- |
| vm-web → vm-db          | BLOQUÉ      | Mouvement latéral interdit |
| vm-db → Internet        | BLOQUÉ      | Exfiltration impossible    |
| SSH via IP publique     | IMPOSSIBLE  | Aucune IP publique         |
| Internet → snet-data-db | BLOQUÉ      | Zone CDE isolée            |

---

## 5. Exigences Techniques Détaillées

### Exigence 1 — Réseau (Hub & Spoke)

| Req   | Description                                 | Critère d'acceptance                |
| ----- | ------------------------------------------- | ----------------------------------- |
| NET-1 | 4 VNets avec adressages disjoints           | `terraform output` montre 4 VNets   |
| NET-2 | Peerings Hub ↔ Spokes avec Gateway Transit  | Peering status = Connected          |
| NET-3 | Aucun peering direct entre Spokes           | Communication uniquement via Hub FW |
| NET-4 | Plages 10.3/10.4 réservées pour scalabilité | Documenté dans IPAM                 |

### Exigence 2 — Hybridation (VPN)

| Req   | Description                                    | Critère d'acceptance               |
| ----- | ---------------------------------------------- | ---------------------------------- |
| VPN-1 | 2 VPN Gateways (Hub AS 65001, OnPrem AS 65002) | Status = Connected                 |
| VPN-2 | IPsec IKEv2, PSK > 32 caractères               | `az network vpn-connection show`   |
| VPN-3 | BGP activé, routes dynamiques échangées        | Route 10.10.0.0/16 apprise via BGP |
| VPN-4 | PFS activé                                     | Configuration IKE policy           |

### Exigence 3 — Sécurité Zero Trust (NSG/ASG)

| Req   | Description                            | Critère d'acceptance             |
| ----- | -------------------------------------- | -------------------------------- |
| SEC-1 | 4 ASG (web, app, db, bastion)          | Chaque NIC VM attachée à son ASG |
| SEC-2 | NSG deny-all par défaut (prio 4000)    | Effective Security Rules         |
| SEC-3 | Règles basées ASG — pas d'IP statiques | NSG rules source = ASG           |
| SEC-4 | Web ↛ DB directement                   | Test ping depuis vm-web échoue   |

### Exigence 4 — Inspection centralisée

| Req  | Description                                      | Critère d'acceptance                      |
| ---- | ------------------------------------------------ | ----------------------------------------- |
| FW-1 | Azure Firewall Standard dans Hub                 | Firewall provisionné, IP privée 10.0.1.4  |
| FW-2 | UDR 0.0.0.0/0 → FW sur tous les subnets spoke    | Effective Routes vm-web                   |
| FW-3 | Règles applicatives FQDN (Ubuntu, Azure Monitor) | `curl google.com` bloqué                  |
| FW-4 | WAF OWASP 3.2 mode Prevention                    | WAF logs montrent les requêtes inspectées |

### Exigence 5 — PaaS sécurisé

| Req    | Description                                     | Critère d'acceptance                     |
| ------ | ----------------------------------------------- | ---------------------------------------- |
| PAAS-1 | Storage Account + Azure SQL — public access OFF | Portail montre "Public access: Disabled" |
| PAAS-2 | Private Endpoints dans snet-data-pe             | PE status = Approved                     |
| PAAS-3 | DNS privées (blob, sql) liées aux VNets         | `nslookup` → IP 10.2.2.x                 |

### Exigence 6 — Observabilité

| Req   | Description                           | Critère d'acceptance     |
| ----- | ------------------------------------- | ------------------------ |
| OBS-1 | Log Analytics Workspace centralisé    | Données Syslog présentes |
| OBS-2 | NSG Flow Logs v2 sur nsg-web + nsg-db | Flow events dans LAW     |
| OBS-3 | AMA + DCR sur 3 VMs                   | Syslog + perf collectés  |
| OBS-4 | Diagnostic Settings sur FW + Bastion  | AzureDiagnostics peuplé  |
| OBS-5 | Alert Rule > 500 denied / 5 min       | Action Group configuré   |

---

## 6. Livrables Contractuels

| #   | Livrable                               | Format          | Contenu                                              |
| --- | -------------------------------------- | --------------- | ---------------------------------------------------- |
| L1  | Matrice d'Audit & Écarts               | Markdown        | 5 pratiques A→E, règles ANSSI, risques, remédiations |
| L2  | DAT (Dossier d'Architecture Technique) | Markdown/PDF    | HLD, IPAM, matrices de flux, FinOps, DevSecOps       |
| L3  | Code Terraform                         | 16 fichiers .tf | Infrastructure complète déployable et reproductible  |
| L4  | Cahier de Recette                      | Markdown        | 10 preuves ANSSI, commandes, résultats attendus      |

---

## 7. Planning

| Phase    | Tâche                                       | Statut      |
| -------- | ------------------------------------------- | ----------- |
| Phase 0  | Initialisation repo + structure Terraform   | ✅          |
| Phase 1  | Audit ANSSI — Matrice d'écarts (Livrable 1) | ✅          |
| Phase 2  | Réseau — VNets, Subnets, Peerings           | ✅          |
| Phase 3  | Hybridation — VPN IPsec/BGP                 | ✅          |
| Phase 4  | Sécurité — NSG, ASG, deny-all               | ✅          |
| Phase 5  | Compute — 4 VMs Linux                       | ✅          |
| Phase 6  | Firewall — Azure Firewall + UDR             | ✅          |
| Phase 7  | Bastion — Admin sécurisée                   | ✅          |
| Phase 8  | PaaS — Private Endpoints + DNS privées      | ✅          |
| Phase 9  | WAF — Application Gateway v2                | ✅          |
| Phase 10 | Observabilité — SIEM + alertes              | ✅          |
| Phase 11 | Rédaction livrables (L1, L2, L3, L4)        | ✅          |
| Phase 12 | Déploiement Azure + Recette                 | 🔄 En cours |
| Phase 13 | Soutenance orale (14/04)                    | ⏳          |

---

## 8. Budget & FinOps

### 8.1 Estimation des coûts

| Ressource                  | Coût/heure    | Coût/mois (8h/j, 22j) |
| -------------------------- | ------------- | --------------------- |
| Azure Firewall Standard    | ~1,30 €       | ~228 €                |
| VPN Gateway VpnGw1 ×2      | ~0,76 €       | ~134 €                |
| Application Gateway WAF v2 | ~0,25 €       | ~44 €                 |
| Azure Bastion Basic        | ~0,12 €       | ~21 €                 |
| VMs Standard_B1s ×4        | ~0,04 €       | ~7 €                  |
| Log Analytics + Storage    | —             | ~1 €                  |
| **TOTAL**                  | **~2,47 €/h** | **~435 €/mois**       |

### 8.2 Stratégie FinOps (crédits étudiants)

| Levier                                            | Impact                       |
| ------------------------------------------------- | ---------------------------- |
| `terraform destroy` chaque soir                   | **-70%** du coût             |
| `terraform apply` chaque matin (~30 min)          | Infrastructure reproductible |
| VMs B1s (burstable)                               | Plus petit SKU possible      |
| WAF autoscale min_capacity = 0                    | Coût nul au repos            |
| VPN Gateways déployées uniquement pour la recette | Économie ~0,76 €/h           |

> **Budget estimé réel : ~200 € pour 2 semaines** avec la stratégie destroy/apply quotidienne.

---

## 9. Référentiels & Conformité

| Référentiel                       | Couverture                                    |
| --------------------------------- | --------------------------------------------- |
| Guide d'hygiène ANSSI (42 règles) | 10 règles prouvées techniquement (Livrable 4) |
| PCI-DSS v4.0                      | Exigences 1, 2, 4, 8, 10 couvertes            |
| OWASP Top 10                      | WAF OWASP 3.2 mode Prévention                 |
| Azure Well-Architected Framework  | Piliers Sécurité + Coûts                      |

---

## 10. Risques Projet

| Risque                                      | Probabilité | Impact   | Mitigation                                          |
| ------------------------------------------- | ----------- | -------- | --------------------------------------------------- |
| Dépassement budget Azure                    | Moyenne     | Haut     | Destroy quotidien + monitoring coûts                |
| VPN Gateway longue à provisionner (~25 min) | Haute       | Moyen    | Déployer en dernier, variable `deploy_vpn_gateways` |
| Changement d'API AzureRM                    | Faible      | Moyen    | Provider 4.x pinné dans versions.tf                 |
| Perte de state Terraform                    | Faible      | Critique | Backend remote dans Storage Account                 |

---

## 11. Glossaire

| Terme           | Définition                                                                              |
| --------------- | --------------------------------------------------------------------------------------- |
| **Hub & Spoke** | Topologie réseau étoilée avec un VNet central (Hub) et des VNets périphériques (Spokes) |
| **ASG**         | Application Security Group — label logique attaché aux NICs pour les règles NSG         |
| **NSG**         | Network Security Group — firewall L4 natif Azure                                        |
| **UDR**         | User Defined Route — table de routage personnalisée                                     |
| **WAF**         | Web Application Firewall — protection applicative L7                                    |
| **PE**          | Private Endpoint — interface réseau privée pour accéder aux services PaaS               |
| **BGP**         | Border Gateway Protocol — protocole de routage dynamique                                |
| **IKEv2**       | Internet Key Exchange v2 — protocole de négociation de clés pour IPsec                  |
| **CDE**         | Cardholder Data Environment — périmètre contenant les données bancaires (PCI-DSS)       |
| **AMA**         | Azure Monitor Agent — agent de collecte de logs/metrics                                 |
| **DCR**         | Data Collection Rule — règle définissant quoi collecter et où l'envoyer                 |
| **KQL**         | Kusto Query Language — langage de requête pour Log Analytics                            |
