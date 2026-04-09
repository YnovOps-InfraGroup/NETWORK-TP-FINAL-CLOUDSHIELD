# 💰 Analyse des Coûts — Cloud Shield

> Rapport généré via **Infracost v0.10.43** — Source : `terraform/`
> 📊 [Rapport HTML complet](infracost-report.html) | Devise : EUR (taux 1 USD ≈ 0,92 €)

---

## Résumé

|                           | Valeur                 |
| ------------------------- | ---------------------- |
| **Resources détectées**   | 81                     |
| **Resources estimées**    | 20                     |
| **Resources gratuites**   | 61                     |
| **Coût mensuel de base**  | **~57,90 € / mois**    |
| **Coût variable (usage)** | Dépend de l'usage réel |

> ⚠️ Les ressources optionnelles (Azure Firewall ~828 €/mois, Bastion Standard ~129 €/mois, VPN Gateways ~258 €/mois, Application Gateway WAF ~230 €/mois) sont **désactivées par défaut** via les variables `deploy_*`. Elles ne sont déployées qu'à la demande.

---

## Détail par ressource — Coûts fixes

| Ressource                         | Détail                | Coût mensuel |
| --------------------------------- | --------------------- | ------------ |
| `vm_web` — Standard_B1s           | Instance Linux (730h) | 7,92 €       |
| `vm_web` — Disque OS              | Stockage S4 LRS       | 1,55 €       |
| `vm_app` — Standard_B1s           | Instance Linux (730h) | 7,92 €       |
| `vm_app` — Disque OS              | Stockage S4 LRS       | 1,55 €       |
| `vm_db` — Standard_B1s            | Instance Linux (730h) | 7,92 €       |
| `vm_db` — Disque OS               | Stockage S4 LRS       | 1,55 €       |
| `vm_onprem` — Standard_B1s        | Instance Linux (730h) | 7,92 €       |
| `vm_onprem` — Disque OS           | Stockage S4 LRS       | 1,55 €       |
| `pe_blob` — Private Endpoint      | 730h                  | 6,72 €       |
| `pe_sql` — Private Endpoint       | 730h                  | 6,72 €       |
| `fintechdb` — Azure SQL Basic     | Compute (730h)        | 5,62 €       |
| `privatelink.blob` — DNS Zone     | Zone hébergée         | 0,46 €       |
| `privatelink.database` — DNS Zone | Zone hébergée         | 0,46 €       |
| **TOTAL FIXE**                    |                       | **~57,86 €** |

---

## Coûts variables (selon l'usage)

| Ressource                         | Coût à l'usage                            |
| --------------------------------- | ----------------------------------------- |
| `law-cloudshield` — Log Analytics | 2,54 €/Go ingéré · 0,023 €/Go archivé     |
| `storage_logs` — Azure Storage    | 0,018 €/Go · 0,054 €/10k requêtes         |
| `storage_backup` — Azure Storage  | 0,018 €/Go · 0,054 €/10k requêtes         |
| NSG Flow Logs × 2                 | 0,46 €/Go · 3,22 €/Go (Traffic Analytics) |
| VNet Peering × 4                  | 0,009 €/Go (entrant + sortant)            |
| `fintechdb` — Backup / PITR       | 0,23 €/Go (RA-GRS)                        |

---

## Ressources optionnelles (désactivées)

Ces ressources sont dans le code Terraform mais **non déployées en production courante** pour maîtriser les coûts :

| Ressource                    | Coût estimé       | Variable                     |
| ---------------------------- | ----------------- | ---------------------------- |
| Azure Firewall Standard      | ~828 €/mois       | `deploy_firewall = true`     |
| Azure Bastion Standard       | ~129 €/mois       | `deploy_bastion = true`      |
| VPN Gateway × 2 + Connection | ~258 €/mois       | `deploy_vpn_gateways = true` |
| Application Gateway v2 + WAF | ~230 €/mois       | `deploy_waf = true`          |
| **Total si tout activé**     | **~1 500 €/mois** |                              |

---

## Stratégie FinOps

- **Usage quotidien** : `terraform apply` le matin → `terraform destroy` le soir → **coût réel ≈ 2–4 €/jour**
- **Ressources coûteuses 1h max** : Firewall, Bastion, VPN, WAF déployés uniquement pour les démos/tests
- Voir [Stratégie FinOps complète](../Reference/STRATEGIE-FINOPS.md)
