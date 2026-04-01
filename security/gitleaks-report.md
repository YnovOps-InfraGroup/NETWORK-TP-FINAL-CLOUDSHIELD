# Rapport gitleaks — Cloud Shield

> Généré le 2026-04-01 | Mode : filesystem scan (--no-git)

## Résumé

| Métrique | Valeur |
|----------|--------|
| 🔴 Leaks détectés | **0** |
| Fichiers scannés | ~35 |
| Taille scannée | ~1 MB |
| Durée | 891ms |

**Aucun secret détecté dans les fichiers trackés.**

## Fichiers exclus du scan (gitignore)

| Fichier | Raison |
|---------|--------|
| `terraform/terraform.tfvars` | Secrets — gitignore |
| `.terraform/` | Cache provider — gitignore |

## Variables sensibles protégées

| Variable | Protection |
|----------|------------|
| `subscription_id` | tfvars (gitignore) |
| `tenant_id` | tfvars (gitignore) |
| `vm_ssh_public_key` | tfvars (gitignore) |
| `vpn_shared_key` | tfvars (gitignore) |
| `sql_admin_password` | tfvars (gitignore) |
| `sql_admin_login` | tfvars (gitignore) |
| `vm_admin_username` | tfvars (gitignore) |

## Conclusion

Aucune fuite de secret dans le code source commité.
Architecture conforme aux règles ANSSI R67 (gestion des secrets).
