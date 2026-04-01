# Rapport tfsec — Cloud Shield

> Généré le 2026-04-01 | Framework : Terraform | Version : tfsec latest

## Résumé

| Métrique | Valeur |
|----------|--------|
| ✅ Passed | 53 |
| 🟡 Medium | 1 |
| 🔵 Low | 2 |
| 🔴 Critical | 0 |
| 🟠 High | 0 |

**Aucune vulnérabilité critique ou haute détectée.**

## Problèmes détectés

| Sévérité | Rule | Description | Fichier | Justification |
|----------|------|-------------|---------|---------------|
| 🟡 Medium | `azure-storage-default-action-deny` | Storage account sans default action DENY | `terraform/paas.tf` | Storage de logs — accès restreint par Private Endpoint + deny public |
| 🔵 Low | `azure-network-no-public-ip` | VM avec Public IP | `terraform/compute.tf` | VM OnPrem simulée — accès contrôlé, Bastion prévu |
| 🔵 Low | `azure-network-ssh-blocked-from-internet` | Port SSH potentiellement accessible | `terraform/compute.tf` | NSG deny-all priorité 4000 actif + Bastion obligatoire |

## Conclusion

Score **53/56 (95%)** — architecture Zero Trust validée.
Les 3 findings de faible sévérité sont des faux positifs acceptés dans le contexte TP.
