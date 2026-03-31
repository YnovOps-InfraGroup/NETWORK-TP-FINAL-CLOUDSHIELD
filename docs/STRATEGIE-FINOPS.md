# <i class="fa-solid fa-coins"></i> Stratégie FinOps

<div style="margin-bottom:1.5em">
  <img src="https://img.shields.io/badge/Budget_PoC-~200%E2%82%AC-3fb950?style=flat-square" alt="Budget" />
  <img src="https://img.shields.io/badge/Strat%C3%A9gie-Destroy%2FApply_quotidien-d29922?style=flat-square" alt="Stratégie" />
  <img src="https://img.shields.io/badge/%C3%89conomie--70%25-0078D4?style=flat-square" alt="Economy" />
</div>

## Estimation des coûts

| Ressource                  | Coût/heure    | Coût/jour (8h) | Coût/mois (22j) |
| -------------------------- | ------------- | -------------- | --------------- |
| Azure Firewall Standard    | ~1,30 €       | ~10,40 €       | ~228 €          |
| VPN Gateway VpnGw1 ×2      | ~0,76 €       | ~6,08 €        | ~134 €          |
| Application Gateway WAF v2 | ~0,25 €       | ~2,00 €        | ~44 €           |
| Azure Bastion Basic        | ~0,12 €       | ~0,96 €        | ~21 €           |
| VMs Standard_B1s ×4        | ~0,04 €       | ~0,32 €        | ~7 €            |
| Log Analytics + Storage    | —             | —              | ~1 €            |
| **TOTAL**                  | **~2,47 €/h** | **~19,76 €**   | **~435 €**      |

## Leviers d'économie

| Levier                          | Impact            | Détail                        |
| ------------------------------- | ----------------- | ----------------------------- |
| `terraform destroy` chaque soir | **-70%**          | Ne payer que 8h/jour          |
| `terraform apply` chaque matin  | ~30 min           | Infrastructure reproductible  |
| Phase 1 sans VPN                | **-0,76 €/h**     | `deploy_vpn_gateways = false` |
| VMs B1s (burstable)             | Coût minimal      | ~0,01 €/h par VM              |
| WAF `min_capacity = 0`          | Coût nul au repos | Autoscale natif               |
| Bastion Basic                   | -50% vs Standard  | Suffisant pour SSH            |

## Budget réel

| Scénario                                       | Coût estimé |
| ---------------------------------------------- | ----------- |
| **PoC 2 semaines** (8h/j, destroy chaque soir) | **~200 €**  |
| Phase 1 seule (sans VPN)                       | ~135 €      |
| Phase 2 complète (VPN activé 2 jours)          | ~210 €      |
| ⚠️ 1 mois 24/7 (NE PAS FAIRE)                  | ~1 780 €    |

## Règles d'or

1. **Jamais laisser tourner la nuit** — Firewall seul = 20,80 €/nuit gaspillés
2. **VPN uniquement pour la recette** — +18 €/jour
3. **Vérifier les coûts chaque matin** — `az consumption usage list`
4. **Destroy le vendredi soir** — Week-end = 118 € économisés
