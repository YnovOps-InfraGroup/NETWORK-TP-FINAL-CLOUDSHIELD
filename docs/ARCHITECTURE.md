# 🏗️ Architecture Cloud Shield — Schémas Infrastructure

> Source de vérité : fichiers Terraform (`variables.auto.tfvars` + `.tf`)
> Rendu natif GitHub & Docsify via Mermaid.js

---

## 1. Schémas


![Schéma Azure Cloud Shield](assets/diagrams/cloudshield-azure-icons.png)

- PNG: [assets/diagrams/cloudshield-azure-icons.png](assets/diagrams/cloudshield-azure-icons.png)
- SVG: [assets/diagrams/cloudshield-azure-icons.svg](assets/diagrams/cloudshield-azure-icons.svg)
- Source DOT: [assets/diagrams/cloudshield-azure-icons.dot](assets/diagrams/cloudshield-azure-icons.dot)

---

## 2. Vue Globale — Hub & Spoke

```mermaid
graph TB
    INTERNET(("🌐 Internet"))

    subgraph ONPREM["🏢 On-Premises Simulé — 10.10.0.0/16"]
        direction TB
        VM_ONPREM["🖥️ vm-onprem\n10.10.1.4"]
        GW_ONPREM["🔒 VPN Gateway\nBGP ASN 65002\n10.10.0.0/27"]
    end

    subgraph HUB["🔵 VNet Hub — 10.0.0.0/16"]
        direction TB
        subgraph HUB_SUBNETS["Subnets Hub"]
            SNET_FW["AzureFirewallSubnet\n10.0.1.0/26"]
            SNET_BASTION["AzureBastionSubnet\n10.0.2.0/26"]
            SNET_GW["GatewaySubnet\n10.0.3.0/27"]
        end
        FIREWALL["🔥 Azure Firewall Standard\nUDR → Spoke-Prod\nUDR → Spoke-Data"]
        BASTION["🛡️ Azure Bastion Basic\nAccès SSH/RDP sécurisé"]
        VPN_GW["🔒 VPN Gateway\nBGP ASN 65001\nIPsec/IKEv2"]
    end

    subgraph SPOKEPROD["🟢 VNet Spoke-Prod — 10.1.0.0/16"]
        direction TB
        subgraph PROD_SUBNETS["Subnets Production"]
            SNET_WAF["SubnetWAF\n10.1.3.0/24"]
            SNET_WEB["SubnetWeb\n10.1.1.0/24"]
            SNET_APP["SubnetApp\n10.1.2.0/24"]
        end
        WAF["⚡ App Gateway WAF v2\nOWASP 3.2 — Prevention"]
        VM_WEB["🌐 vm-web\n10.1.1.4\nFlask :80"]
        VM_APP["⚙️ vm-app\n10.1.2.4\nFlask :8080"]
    end

    subgraph SPOKEDATA["🔴 VNet Spoke-Data — 10.2.0.0/16"]
        direction TB
        subgraph DATA_SUBNETS["Subnets Data"]
            SNET_DB["SubnetDB\n10.2.1.0/24"]
            SNET_PE["SubnetPE\n10.2.2.0/24"]
        end
        VM_DB["🗄️ vm-db\n10.2.1.4\nPostgreSQL :5432"]
        PE_SQL["🔗 Private Endpoint SQL\n10.2.2.4"]
        PE_BLOB["🔗 Private Endpoint Blob\n10.2.2.5"]
    end

    subgraph PAAS["☁️ PaaS (sans endpoint public)"]
        SQL["🗃️ Azure SQL Database\nBasic — PrivateLink"]
        STORAGE["📦 Storage Account\nBlob — PrivateLink"]
    end

    subgraph OBS["📊 Observabilité"]
        LAW["Log Analytics\nrétention 30j"]
        ALERTS["⚠️ 4 Alertes SecOps\nFirewall / NSG / Delete / Health"]
    end

    %% Flux Internet
    INTERNET -->|"HTTPS :443"| WAF

    %% WAF → Web → App → DB
    WAF -->|"HTTP :80\nNSG autorisé"| VM_WEB
    VM_WEB -->|"HTTP :8080\nASG web→app"| VM_APP
    VM_APP -->|"TCP :5432\nASG app→db"| VM_DB

    %% Private Endpoints
    VM_APP -->|"privatelink"| PE_SQL
    VM_APP -->|"privatelink"| PE_BLOB
    PE_SQL -->|"private"| SQL
    PE_BLOB -->|"private"| STORAGE

    %% Hub peerings
    HUB <-->|"VNet Peering\nallow_forwarded"| SPOKEPROD
    HUB <-->|"VNet Peering\nallow_forwarded"| SPOKEDATA

    %% Firewall contrôle egress
    SNET_FW --- FIREWALL
    SPOKEPROD -->|"UDR 0.0.0.0/0\n→ Firewall"| FIREWALL
    SPOKEDATA -->|"UDR 0.0.0.0/0\n→ Firewall"| FIREWALL
    FIREWALL -->|"egress filtré"| INTERNET

    %% VPN hybridation
    GW_ONPREM <-->|"IPsec/IKEv2\nBGP"| VPN_GW
    VM_ONPREM --> GW_ONPREM

    %% Bastion admin
    BASTION -.->|"SSH/RDP\nBastion uniquement"| VM_WEB
    BASTION -.->|"SSH/RDP"| VM_APP
    BASTION -.->|"SSH/RDP"| VM_DB

    %% Observabilité
    SPOKEPROD -->|"Flow Logs"| LAW
    SPOKEDATA -->|"Flow Logs"| LAW
    LAW --> ALERTS

    %% Styles
    classDef hub fill:#1565C0,stroke:#0D47A1,color:#fff
    classDef spoke_prod fill:#2E7D32,stroke:#1B5E20,color:#fff
    classDef spoke_data fill:#B71C1C,stroke:#7F0000,color:#fff
    classDef onprem fill:#F57F17,stroke:#E65100,color:#fff
    classDef paas fill:#4A148C,stroke:#311B92,color:#fff
    classDef obs fill:#424242,stroke:#212121,color:#fff
    classDef internet fill:#006064,stroke:#004D40,color:#fff

    class FIREWALL,BASTION,VPN_GW,SNET_FW,SNET_BASTION,SNET_GW hub
    class WAF,VM_WEB,VM_APP,SNET_WAF,SNET_WEB,SNET_APP spoke_prod
    class VM_DB,PE_SQL,PE_BLOB,SNET_DB,SNET_PE spoke_data
    class VM_ONPREM,GW_ONPREM onprem
    class SQL,STORAGE paas
    class LAW,ALERTS obs
    class INTERNET internet
```

---

## 3. Zero Trust — Matrice de Flux East-West

```mermaid
flowchart LR
    subgraph TIERS["Micro-segmentation par ASG"]
        direction TB
        INTERNET(("🌐 Internet"))
        WAF["⚡ WAF\nSubnetWAF\n10.1.3.0/24"]
        WEB["🌐 Tier Web\nasg-web\n10.1.1.0/24"]
        APP["⚙️ Tier App\nasg-app\n10.1.2.0/24"]
        DB["🗄️ Tier DB\nasg-db\n10.2.1.0/24"]
        BASTION["🛡️ Bastion\nSubnetBastion\n10.0.2.0/26"]
    end

    %% Flux AUTORISÉS
    INTERNET -->|"✅ HTTPS :443"| WAF
    WAF -->|"✅ HTTP :80\nNSG priority 100"| WEB
    WEB -->|"✅ HTTP :8080\nASG web→app\npriority 110"| APP
    APP -->|"✅ TCP :5432\nASG app→db\npriority 110"| DB
    BASTION -->|"✅ SSH :22 / RDP :3389\npriority 100"| WEB
    BASTION -->|"✅ SSH :22 / RDP :3389"| APP
    BASTION -->|"✅ SSH :22 / RDP :3389"| DB

    %% Flux BLOQUÉS
    INTERNET -. "❌ Deny\npriority 4000" .-> WEB
    INTERNET -. "❌ Deny\npriority 4000" .-> DB
    WEB -. "❌ DB inaccessible\nsans passer par App" .-> DB
    DB -. "❌ Aucun flux\nvers Internet" .-> INTERNET
    WEB -. "❌ Aucun flux\ndirect vers Internet" .-> INTERNET

    classDef allowed fill:#1B5E20,stroke:#388E3C,color:#fff
    classDef blocked fill:#B71C1C,stroke:#D32F2F,color:#fff
    classDef neutral fill:#1565C0,stroke:#1976D2,color:#fff

    class WAF,WEB,APP,DB,BASTION neutral
    class INTERNET neutral
```

---

## 4. Dépendances Terraform — Ressources Clés

```mermaid
graph LR
    subgraph RG["rg-cloudshield-prod — francecentral"]
        subgraph NETWORK["Réseau"]
            HUB["vnet-hub\n10.0.0.0/16"]
            PROD["vnet-spoke-prod\n10.1.0.0/16"]
            DATA["vnet-spoke-data\n10.2.0.0/16"]
            ONPREM["vnet-onprem-sim\n10.10.0.0/16"]
        end

        subgraph SECURITY["Sécurité"]
            FW["azurerm_firewall\nfw-cloudshield"]
            FW_POL["azurerm_firewall_policy\nfwpol-cloudshield"]
            NGS_WEB["azurerm_nsg\nnsg-web"]
            NSG_APP["azurerm_nsg\nnsg-app"]
            NSG_DB["azurerm_nsg\nnsg-db"]
            ASG_WEB["asg-web"]
            ASG_APP["asg-app"]
            ASG_DB["asg-db"]
        end

        subgraph COMPUTE["Compute"]
            VMWEB["vm-web\nB1s"]
            VMAPP["vm-app\nB1s"]
            VMDB["vm-db\nB1s"]
            VMONPREM["vm-onprem\nB1s"]
        end

        subgraph PAAS_RES["PaaS"]
            SQLSRV["sql-cloudshield-*\nAzure SQL"]
            STLOG["stcloudshield*\nBlob Logs"]
            PE1["pe-sql\nprivatelink.sql"]
            PE2["pe-blob\nprivatelink.blob"]
        end

        subgraph UDR_RES["Routing UDR"]
            RT_PROD["rt-spoke-prod\n0.0.0.0/0 → Firewall"]
            RT_DATA["rt-spoke-data\n0.0.0.0/0 → Firewall"]
        end

        subgraph VPN_RES["VPN (deploy_vpn_gateways=false)"]
            VPN_HUB["vpn-gw-hub\nBGP 65001"]
            VPN_ONP["vpn-gw-onprem\nBGP 65002"]
        end
    end

    %% Dépendances réseau
    FW_POL --> FW
    HUB --> FW
    HUB --> NGS_WEB
    PROD --> NGS_WEB
    PROD --> NSG_APP
    DATA --> NSG_DB

    %% UDR → Firewall
    RT_PROD -->|"nexthop = FW IP"| FW
    RT_DATA -->|"nexthop = FW IP"| FW
    PROD --> RT_PROD
    DATA --> RT_DATA

    %% VMs → NSG/ASG
    VMWEB --> ASG_WEB
    VMAPP --> ASG_APP
    VMDB --> ASG_DB

    %% Private Endpoints → PaaS
    PE1 --> SQLSRV
    PE2 --> STLOG
    DATA --> PE1
    DATA --> PE2

    %% VPN
    HUB --> VPN_HUB
    ONPREM --> VPN_ONP
    VPN_HUB <-->|"IPsec/BGP"| VPN_ONP

    classDef network fill:#1565C0,stroke:#0D47A1,color:#fff
    classDef security fill:#B71C1C,stroke:#7F0000,color:#fff
    classDef compute fill:#2E7D32,stroke:#1B5E20,color:#fff
    classDef paas fill:#4A148C,stroke:#311B92,color:#fff
    classDef routing fill:#E65100,stroke:#BF360C,color:#fff
    classDef vpn fill:#37474F,stroke:#263238,color:#fff

    class HUB,PROD,DATA,ONPREM network
    class FW,FW_POL,NGS_WEB,NSG_APP,NSG_DB,ASG_WEB,ASG_APP,ASG_DB security
    class VMWEB,VMAPP,VMDB,VMONPREM compute
    class SQLSRV,STLOG,PE1,PE2 paas
    class RT_PROD,RT_DATA routing
    class VPN_HUB,VPN_ONP vpn
```

---

## 5. Plan d'Adressage IP (IPAM)

| Composant      | VNet / Subnet       | CIDR           | Rôle                          |
| -------------- | ------------------- | -------------- | ----------------------------- |
| **Hub**        | vnet-hub            | `10.0.0.0/16`  | Sécurité, egress, hybridation |
| ↳              | AzureFirewallSubnet | `10.0.1.0/26`  | Azure Firewall Standard       |
| ↳              | AzureBastionSubnet  | `10.0.2.0/26`  | Azure Bastion Basic           |
| ↳              | GatewaySubnet       | `10.0.3.0/27`  | VPN Gateway                   |
| **Spoke-Prod** | vnet-spoke-prod     | `10.1.0.0/16`  | Application 3-tiers           |
| ↳              | SubnetWAF           | `10.1.3.0/24`  | Application Gateway WAF       |
| ↳              | SubnetWeb           | `10.1.1.0/24`  | vm-web Flask :80              |
| ↳              | SubnetApp           | `10.1.2.0/24`  | vm-app Flask :8080            |
| **Spoke-Data** | vnet-spoke-data     | `10.2.0.0/16`  | Base de données & PaaS        |
| ↳              | SubnetDB            | `10.2.1.0/24`  | vm-db PostgreSQL :5432        |
| ↳              | SubnetPE            | `10.2.2.0/24`  | Private Endpoints             |
| **OnPrem Sim** | vnet-onprem-sim     | `10.10.0.0/16` | Lyon datacenter simulé        |
| ↳              | GatewaySubnet       | `10.10.0.0/27` | VPN Gateway OnPrem            |
| ↳              | SubnetSrv           | `10.10.1.0/24` | vm-onprem                     |
