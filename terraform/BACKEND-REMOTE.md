# 🔐 Backend Remote Azure — Configuration & Migration

## État actuel

✅ **Backend configuré** : Azure Blob Storage (`stoagreg3sr`)
✅ **State centralisé** : `/tfstate/cloudshield/terraform.tfstate`
✅ **Authentication** : Azure AD (`use_azuread_auth = true`)

## Pourquoi Remote Backend ?

| Aspect            | Local                                | Remote (Azure)            |
| ----------------- | ------------------------------------ | ------------------------- |
| **Sécurité**      | ❌ Secrets en plaintext              | ✅ Chiffré au repos       |
| **Collaboration** | ❌ Une personne à la fois            | ✅ Multiples utilisateurs |
| **Versioning**    | ❌ Pas de backup                     | ✅ Historique Azure       |
| **Locking**       | ⚠️ Fichier `.lock`                   | ✅ Blob lock Azure        |
| **Récupération**  | ❌ Perte du dossier = perte du state | ✅ Toujours disponible    |

## Architecture

```
Local Machine (tf code + .terraform/)
        ↓
   terraform init / plan / apply
        ↓
   Backend: azurerm (backend.tf)
        ↓
   stoagreg3sr (RG-CORE-STORAGE)
        ↓
   Container: tfstate
        ↓
   Blob: cloudshield/terraform.tfstate
```

## Fichiers clés

- **`backend.tf`** — Configuration backend (ne pas modifier)
- **`.terraform.lock.hcl`** — Lock file (À COMMITTER sur Git)
- **`.terraform/`** — Répertoire local (À IGNORER, sauf `.terraform.lock.hcl`)

## Commandes

### Initialiser le backend (première fois)

```bash
cd terraform
terraform init
```

### Réinitialiser si changements du backend

```bash
terraform init -reconfigure
```

### Vérifier l'état du backend

```bash
terraform state list      # Lister les ressources managées
terraform state show      # Afficher une ressource spécifique
```

### Voir le lock actif (Azure)

```bash
az storage blob metadata show \
  --account-name stoagreg3sr \
  --container-name tfstate \
  --name cloudshield/terraform.tfstate
```

## ⚠️ ATTENTION : Ne jamais modifier le state directement

```bash
# ❌ DANGER — Ne pas faire ça
rm terraform.tfstate
terraform state rm azurerm_resource.name

# ✅ Utilisez les commandes Terraform appropriées
terraform apply
terraform destroy
```

## Pipeline Azure DevOps

Les pipelines injectent automatiquement les variables d'env :

```yaml
export ARM_STORAGE_ACCOUNT_NAME=stoagreg3sr
export ARM_CONTAINER_NAME=tfstate
export ARM_KEY=cloudshield/terraform.tfstate
```

Pour local, utiliser `terraform init -reconfigure`.

---

**Version** : 2.0 (Remote Backend Azure)
**Date** : 01/04/2026
**Responsable** : Architecture Infrastructure Cloud Shield
