# Rapport Infracost — Cloud Shield

> Généré le 2026-04-01 | Phase : Éco (Firewall/WAF/Bastion désactivés)

## Coût Phase Éco

| Ressource | SKU | Coût/mois | Coût/jour |
|-----------|-----|-----------|-----------|
| `azurerm_linux_virtual_machine` × 4 | Standard_B1s | $41.20 | $1.37 |
| `azurerm_private_endpoint` × 2 | Standard | $14.60 | $0.49 |
| `azurerm_mssql_server` + DB | Basic 5 DTU | $6.11 | $0.20 |
| `azurerm_storage_account` × 2 | LRS Standard | $4.61 | $0.15 |
| `azurerm_public_ip` × 3 | Static Basic | $10.95 | $0.37 |
| `azurerm_log_analytics_workspace` | Pay-as-you-go | $5.46 | $0.18 |
| Peering + DNS + divers | — | ~$20.00 | $0.66 |
| **TOTAL Phase Éco** | | **$62.93/mois** | **~$2.10/jour** |

## Projection Phase Complète (Firewall + WAF + Bastion)

| Ressource ajoutée | Coût/mois | Coût/jour |
|-------------------|-----------|-----------|
| `azurerm_firewall` Standard | $912.50 | $30.42 |
| `azurerm_application_gateway` WAF_v2 | $328.50 | $10.95 |
| `azurerm_bastion_host` Basic | $138.70 | $4.62 |
| `azurerm_virtual_network_gateway` × 2 | $555.00 | $18.50 |
| **TOTAL Phase Complète** | **~$1,997.63** | **~$66.58** |

## Stratégie FinOps

| Optimisation | Économie |
|-------------|---------|
| VMs B1s au lieu de B2s | -50% compute |
| SQL Basic au lieu de Standard | -80% SQL |
| Firewall désactivé hors soutenance | -$30.42/j |
| Auto-shutdown VMs à 20h00 | -30% VM cost |
| `terraform destroy` quotidien si pas utilisé | -100% |

## Workflow Infracost recommandé

```bash
# 1. Avant chaque apply — estimer le coût
terraform plan -out=plan.tfplan
infracost diff --path . --compare-to security/infracost-current.json

# 2. Valider le coût
# Si acceptable → apply

# 3. Après apply — mettre à jour la baseline
infracost breakdown --path . --format json --out-file security/infracost-current.json
```
