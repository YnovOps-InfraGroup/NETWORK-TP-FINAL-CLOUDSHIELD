# 🏗️ Architecture Cloud Shield — Schéma Infra

> **Source de vérité** : généré depuis le code Terraform via InfraMap v0.7.0
> Rendu natif GitHub / Docsify via Mermaid.js

---

## Hub & Spoke — Vue Globale

```mermaid
graph TB
    subgraph INTERNET["🌐 Internet"]
        USER["👤 Utilisateur"]
    end

    subgraph ONPREM["🏢 On-Prem Simulé — 192.168.10.0/24"]
        VM_ONPREM["🖥️ vm-onprem\n10.10.1.4"]
        ONPREM_GW["🔒 VPN GW OnPrem\nBGP 65002"]
    end

    subgraph HUB["🔵 VNet Hub — 10.0.0.0/16 — rg-cloudshield-hub"]
        FW["🔥 Azure Firewall\nStandard\n10.0.0.4"]
        BASTION["🏰 Azure Bastion\nBasic\nAzureBastionSubnet"]
        HUB_GW["🔒 VPN GW Hub\nBGP 65001"]
        FW_PIP["🌐 PIP Firewall"]
        BASTION_PIP["🌐 PIP Bastion"]
        VPN_PIP["🌐 PIP VPN"]
        WAF_PIP["🌐 PIP WAF"]
    end

    subgraph WAF_ZONE["🛡️ WAF Zone — Hub"]
        WAF["⚡ App Gateway WAF v2\nOWASP 3.2 Prevention\n10.0.3.0/24"]
    end

    subgraph SPOKE_PROD["🟢 VNet Spoke-Prod — 10.1.0.0/16 — rg-cloudshield-prod"]
        subgraph WEB_TIER["Web Tier — 10.1.1.0/24"]
            VM_WEB["🌐 vm-web\n10.1.1.4\nFlask App"]
        end
        subgraph APP_TIER["App Tier — 10.1.2.0/24"]
            VM_APP["⚙️ vm-app\n10.1.2.4\nMiddleware"]
        end
    end

    subgraph SPOKE_DATA["🔴 VNet Spoke-Data — 10.2.0.0/16 — rg-cloudshield-prod"]
        subgraph DB_TIER["DB Tier — 10.2.1.0/24"]
            VM_DB["🗄️ vm-db\n10.2.1.4\nPostgreSQL"]
        end
        subgraph PE_TIER["Private Endpoints — 10.2.3.0/24"]
            PE_SQL["🔌 PE SQL Server"]
            PE_BLOB["🔌 PE Storage Blob"]
        end
        SQL["🗃️ Azure SQL\nBasic DTU"]
        STORAGE["📦 Azure Storage\nBlob LRS"]
    end

    subgraph DNS["🔍 DNS Privé"]
        DNS_SQL["privatelink.database.windows.net"]
        DNS_BLOB["privatelink.blob.core.windows.net"]
    end

    subgraph OBS["📊 Observabilité"]
        LAW["📋 Log Analytics\n30 jours rétention"]
        ALERTS["🚨 4 Alertes SecOps"]
        FLOWLOGS["📈 VNet Flow Logs"]
    end

    %% Flux Internet → WAF → Web
    USER -->|HTTPS 443| WAF_PIP
    WAF_PIP --> WAF
    WAF -->|inspecté| VM_WEB

    %% Flux Web → App → DB (via Firewall East-West)
    VM_WEB -->|8080 via FW| FW
    FW -->|filtré| VM_APP
    VM_APP -->|5432 via FW| FW
    FW -->|filtré| VM_DB

    %% Trafic sortant via Firewall (UDR)
    VM_WEB -->|UDR 0.0.0.0/0| FW
    VM_APP -->|UDR 0.0.0.0/0| FW
    VM_DB -->|UDR 0.0.0.0/0| FW
    FW --> FW_PIP

    %% Admin via Bastion uniquement
    USER -->|HTTPS 443| BASTION_PIP
    BASTION_PIP --> BASTION
    BASTION -->|SSH 22 / RDP 3389| VM_WEB
    BASTION -->|SSH 22 / RDP 3389| VM_APP
    BASTION -->|SSH 22 / RDP 3389| VM_DB

    %% Hybridation VPN IPsec/BGP
    ONPREM_GW <-->|IPsec/IKEv2\nBGP 65001↔65002| HUB_GW
    HUB_GW --> HUB
    VM_ONPREM --> ONPREM_GW

    %% Peerings Hub & Spoke
    HUB <-->|VNet Peering| SPOKE_PROD
    HUB <-->|VNet Peering| SPOKE_DATA
    HUB <-->|VNet Peering| ONPREM

    %% PaaS via Private Endpoints
    PE_SQL --> SQL
    PE_BLOB --> STORAGE
    VM_DB --> PE_SQL
    VM_APP --> PE_BLOB

    %% DNS privé
    PE_SQL --> DNS_SQL
    PE_BLOB --> DNS_BLOB

    %% Observabilité
    VM_WEB & VM_APP & VM_DB -.->|AMA Agent| LAW
    LAW --> FLOWLOGS
    LAW --> ALERTS

    %% Styles
    classDef hub fill:#0078d4,stroke:#005a9e,color:#fff
    classDef spoke_prod fill:#107c10,stroke:#004b00,color:#fff
    classDef spoke_data fill:#c50f1f,stroke:#8e0000,color:#fff
    classDef security fill:#ff8c00,stroke:#c45000,color:#fff
    classDef paas fill:#6c2d91,stroke:#4a1f6b,color:#fff
    classDef onprem fill:#767676,stroke:#444,color:#fff
    classDef obs fill:#038387,stroke:#005f63,color:#fff

    class FW,BASTION,HUB_GW,FW_PIP,BASTION_PIP,VPN_PIP hub
    class WAF,WAF_PIP security
    class VM_WEB,VM_APP spoke_prod
    class VM_DB,PE_SQL,PE_BLOB spoke_data
    class SQL,STORAGE paas
    class VM_ONPREM,ONPREM_GW onprem
    class LAW,ALERTS,FLOWLOGS obs
```

---

## Flux Réseau — Matrice Zero Trust

```mermaid
flowchart LR
    INTERNET(["🌐 Internet"])
    WAF["🛡️ WAF\nOWASP"]
    FW["🔥 Firewall\nAzure"]
    WEB["🌐 vm-web\n10.1.1.4"]
    APP["⚙️ vm-app\n10.1.2.4"]
    DB["🗄️ vm-db\n10.2.1.4"]
    SQL["🗃️ SQL PE\n10.2.3.x"]
    BLOB["📦 Blob PE\n10.2.3.x"]
    BASTION["🏰 Bastion\nAdmin"]
    ADMIN(["👤 Admin"])

    INTERNET -->|443 HTTPS| WAF
    WAF -->|80 inspecté| WEB
    ADMIN -->|443 HTTPS| BASTION
    BASTION -.->|SSH 22| WEB & APP & DB

    WEB -->|via UDR| FW
    FW -->|8080 autorisé| APP
    FW -.->|❌ direct DB| DB

    APP -->|via UDR| FW
    FW -->|5432 autorisé| DB

    DB -->|privé| SQL
    APP -->|privé| BLOB

    style INTERNET fill:#e8f4f8
    style WAF fill:#ff8c00,color:#fff
    style FW fill:#0078d4,color:#fff
    style BASTION fill:#0078d4,color:#fff
    style WEB fill:#107c10,color:#fff
    style APP fill:#107c10,color:#fff
    style DB fill:#c50f1f,color:#fff
    style SQL fill:#6c2d91,color:#fff
    style BLOB fill:#6c2d91,color:#fff
```

---

## Dépendances Terraform — InfraMap

> Fichier DOT brut disponible dans [`docs/inframap.dot`](inframap.dot) —
> Rendu en ligne : [GraphvizOnline](https://dreampuf.github.io/GraphvizOnline/) ou [Kroki](https://kroki.io/)

```mermaid
graph LR
    VHub["vnet-hub\n10.0.0.0/16"]
    VProd["vnet-spoke-prod\n10.1.0.0/16"]
    VData["vnet-spoke-data\n10.2.0.0/16"]
    VOnprem["vnet-onprem\n10.10.0.0/16"]

    GwHub["VPN GW Hub\nBGP 65001"]
    GwOnprem["VPN GW OnPrem\nBGP 65002"]

    VProd --> VHub
    VData --> VHub
    VProd --> GwHub
    VData --> GwHub
    VHub --> VOnprem
    GwHub <--> GwOnprem

    style VHub fill:#0078d4,color:#fff
    style VProd fill:#107c10,color:#fff
    style VData fill:#c50f1f,color:#fff
    style VOnprem fill:#767676,color:#fff
    style GwHub fill:#0078d4,color:#fff
    style GwOnprem fill:#767676,color:#fff
```
