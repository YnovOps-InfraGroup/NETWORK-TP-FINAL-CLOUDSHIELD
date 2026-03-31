Fil rouge des TP
TP1-2 (Cisco Switch/Routeur)
  → Fondements ANSSI : VLANs, SSH, ACL, Port-Security
    TP3 [information manquante – contenu non accessible]
      TP4/4-Suite (OSPF avancé)
        → Concepts routage réutilisés : BGP, filtrage routes, HA timers
          TP5/5-Suite-Cloud [information manquante – contenu non accessible]
            TP6 (Audit ANSSI + Hardening)
              → Maîtrise des 42 règles ANSSI, Gap Analysis, Syslog/NTP
                TP7 (Azure Zero Trust)
                  → Architecture Hub & Spoke, NSG/ASG, VPN BGP, Bastion,
                     Firewall, UDR, Private Endpoints, WAF
                    TP8 / TP8-MAJ (Observabilité)
                      → SIEM, Log Analytics, KQL, Alerting, Incident Response
                        ──────────────────────────────────────
                        CLOUDSHIELD (Projet final)
                        Agrège TOUT : Audit + DAT + IaC Terraform + Prouving

## Briques Azure nécessaires (synthèse)
- VNets (Hub, Spoke-Prod, Spoke-Data, OnPrem-Sim)
- VNet Peerings (Gateway Transit)
- Virtual Network Gateways x2 + Local Network Gateways + Connexion IPsec BGP
- ASG x4, NSG x3
- VMs Linux x4 (sans IP publique)
- Azure Firewall Standard + Firewall Policy + UDR
- Azure Bastion
- Storage Account x2 (PaaS + logs), Azure SQL, Private Endpoints x2, DNS Privées x2
- Application Gateway v2 + WAF
- Log Analytics Workspace, NSG Flow Logs, AMA, DCR, Action Group, Alert Rule

## Vision finale
Le projet CloudShield est la synthèse opérationnelle de l'ensemble du module. Il ne s'agit pas d'un TP supplémentaire mais de l'assemblage de toutes les briques vues en cours, transposées de l'on-premise Cisco vers Azure, formalisées en Terraform, et prouvées techniquement face au jury le 14/04.
