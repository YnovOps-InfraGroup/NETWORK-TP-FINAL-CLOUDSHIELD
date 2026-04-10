# Cloud Shield — Statut du Projet 10/04/2026

**Mise à jour :** Sécurité, documentation, prêt pour soutenance

---

## 🟢 Statut Global

| Aspect | Statut | Details |
|--------|--------|---------|
| **Infrastructure** | ✅ Détruite | Déployée 01/04, détruite 09/04 (budget FinOps 5€ restants) |
| **Code Terraform** | ✅ Validé | 16 fichiers, terraform validate OK, tous pre-commit hooks ✅ |
| **Sécurité** | ✅ Fixes appliquées | Bastion SSH (nsg_app + nsg_db), ANSSI R14 Ed25519, NSG port 22 OK |
| **Documentation** | ✅ Alignée | SKU Standard_B1s, RG = 1 (PoC), tous livrables validés |
| **GitHub Pages** | ✅ Live | ynovops-infragroup.github.io/NETWORK-TP-FINAL-CLOUDSHIELD/ |
| **Wiki GitHub** | ✅ 11 pages | Architecture, Audit ANSSI, Commandes, FinOps |
| **Livrables** | ✅ 4/4 | L1 Audit • L2 DAT • L3 Terraform • L4 Recette (33 preuves) |
| **Soutenance** | 📅 14/04/2026 | Prêt : infra détruite, docs statiques, PowerPoint 13 slides |

---

## 📋 Commits depuis 01/04 (Historique)

### Phase 1 : Audit & Fixes Critique (01/04 − 09/04)

| Commit | Message | Impact |
|--------|---------|--------|
| 822d113 | fix(terraform): ANSSI R14 Ed25519 SSH | SSH algorithm RSA → ED25519 (R14) |
| 514a77d | fix(compute): hardcoded IPs → Terraform interpolation | 10.1.2.4, 10.2.1.4 → dynamiques |
| edc6963 | docs(terraform): normalize comments (16 files) | Suppression emoji, symboles spéciaux |

### Phase 2 : Security & Documentation (09/04 − 10/04)

| Commit | Message | Impact |
|--------|---------|--------|
| 50e2511 | fix(security): add Bastion SSH rules nsg_app/nsg_db | Port 22 de Bastion vers app + db |
| 49c341b | docs: fix SKU (B1s) + clarify RG (1 seul PoC) | Documentation alignée avec code |

---

## 🔧 Fixes Sécurité Appliquées (10/04)

### ✅ Bastion SSH Complet

**Problème :** NSGs app et db n'avaient pas les règles Bastion SSH port 22.

**Solution appliquée :**
- nsg_app : ajout règle `Allow-SSH-from-Bastion` (prio 200, port 22)
- nsg_db : ajout règle `Allow-SSH-from-Bastion` (prio 200, port 22)

**Résultat :**
```
deploy_bastion=true
  → vm-web : SSH ✅
  → vm-app : SSH ✅ (FIXED)
  → vm-db  : SSH ✅ (FIXED)
```

### ✅ Documentation SKU & RG

| Élément | Avant | Après |
|--------|-------|-------|
| **VM SKU** | Documenté B2s | Corrigé Standard_B1s |
| **Resource Groups** | Documenté 4 RGs | Clarifié 1 RG (PoC) |

---

## 📊 État Détaillé par Component

### Réseau (HUB & SPOKE)

| VNet | Subnet | VM | IP Privée | Status |
|------|--------|----|----|--------|
| vnet-hub | AzureBastion | bastion-01 | 10.0.3.4 | Bastion déployé |
| vnet-spoke-prod | snet-prod-web | vm-web | 10.1.1.4 | ✅ NSG web + Bastion SSH |
| vnet-spoke-prod | snet-prod-app | vm-app | 10.1.2.4 | ✅ NSG app + Bastion SSH **(FIXED)** |
| vnet-spoke-data | snet-data-db | vm-db | 10.2.1.4 | ✅ NSG db + Bastion SSH **(FIXED)** |
| vnet-spoke-data | snet-data-pe | (PE) | 10.2.2.4−5 | SQL + Blob Private Endpoints |

### Sécurité (NSG Bastion SSH) — 10/04 Updates

| NSG | Règle SSH | Port | Source | Status |
|-----|-----------|------|--------|--------|
| nsg-web | Allow-SSH-from-Bastion | 22 | var.subnet_bastion | ✅ existant |
| nsg-app | Allow-SSH-from-Bastion | 22 | var.subnet_bastion | ✅ **AJOUTÉ 10/04** |
| nsg-db | Allow-SSH-from-Bastion | 22 | var.subnet_bastion | ✅ **AJOUTÉ 10/04** |

---

## 🎯 Prêt pour Soutenance 14/04

### Checklist Final

- [x] Infrastructure détruite (Terraform destroy réussi)
- [x] Code Terraform compilé et versionné
- [x] Tous les pre-commit hooks passent ✅
- [x] NSG Bastion SSH complet (web, app, db)
- [x] SKU & RG documentation alignée
- [x] 4 livrables complétés (PDF + screenshots)
- [x] GitHub Pages live et navigable
- [x] PowerPoint 13 slides prêt
- [x] 6+ commits atomiques syncés (01/04 − 10/04)

### Ressources Pour Présentation

| Ressource | URL | Status |
|-----------|-----|--------|
| **GitHub Pages** | ynovops-infragroup.github.io/NETWORK-TP-FINAL-CLOUDSHIELD | ✅ Live |
| **PowerPoint** | SOUTENANCE-CloudShield-14-04-2026.pptx | ✅ 13 slides |
| **PDF DAT** | docs/CloudShield-DAT.pdf | ✅ 11 pages |
| **Preuves** | docs/screenshots/PREUVE-{01..11}.png | ✅ 33 images |
| **Code** | terraform/ | ✅ 16 .tf validé |

---

## 📈 Timeline

```
01/04 ─────────── 09/04 ─────────────── 10/04 ───────── 14/04
  │                 │                       │              │
  Deploy            Pre-Destroy             Fixes        Soutenance
  (79 RES)          Audit + Destroy         (NSG SSH)    Présentée
                    (+18 links fixed)       + SKU/RG
```

---

**Dernière mise à jour :** 10 avril 2026 — 16h45
**Prochaine étape :** Soutenance orale 14/04/2026
