# Cloud Shield — Terraform Infrastructure as Code

## 📋 Vue d'ensemble

Infrastructure Azure Zero Trust (Hub & Spoke) déployée via Terraform. 16 fichiers `.tf` logiquement séparés :

- **network.tf** : VNets, Subnets, Peering, NSG basics
- **security.tf** : ASG, NSG rules (micro-segmentation)
- **compute.tf** : VMs Linux (Web, App, DB, OnPrem)
- **firewall.tf** : Azure Firewall + Policies (ANSSI R22/R23)
- **routing.tf** : UDR, Forced Tunneling (conditionnel)
- **bastion.tf** : Azure Bastion (ANSSI R14)
- **ssh.tf** : Clés SSH Ed25519 (ANSSI R14) + Key Vault
- **vpn.tf** : VPN P2S + BGP
- **observability.tf** : Log Analytics + Data Collection Rules + Alertes
- **paas.tf** : Storage Account + Azure SQL (private endpoints)
- **waf.tf** : Application Gateway + WAF Policy
- **rbac.tf** : Azure role assignments
- **acr.tf** : Azure Container Registry (optionnel)
- **monitoring.tf** : Health checks, App Insights
- **resource_groups.tf** : RG principal
- **providers.tf, versions.tf, backend.tf** : Config Terraform

---

## ORDRE DE DÉPLOIEMENT — Important

### Phase 1 : Réseau + VMs (sans firewall + sans Bastion)

```bash
# variables.auto.tfvars (ou CLI override)
deploy_firewall = false
deploy_bastion  = false

terraform apply -auto-approve
```

**Durée** : ~5-7 min
**Résultat** : VNets, VMs + cloud-init réussi

**Raison du `deploy_firewall=false`** :
Sans cette étape, les UDR (User-Defined Routes) créent une **race condition de bootstrap** :

- Les routes de firewall s'activent immédiatement
- Cloud-init a besoin d'accès Internet pour `apt install` (Flask, PostgreSQL)
- UDR blackhole le trafic → cloud-init timeout + erreur

### Phase 2 : Vérifier cloud-init complet

```bash
# Vérifier que le cloud-init s'est bien exécuté
az vm run-command invoke \
  --resource-group "rg-cloudshield-prod" \
  --name "vm-web" \
  --command-id RunShellScript \
  --scripts "cloud-init status --json"
```

Attendre que `status == "done"` avant de continuer.

### Phase 3 : Activer Firewall + Bastion + UDR

```bash
# variables.auto.tfvars
deploy_firewall = true
deploy_bastion  = true

terraform apply -auto-approve
```

**Durée** : ~8-12 min (VPN Gateway + Application Gateway lentes)
**Résultat** : Firewall + UDR + Bastion actifs

À ce stade, l'architecture est **complètement déployée** et les VMs sont :

-  Accessibles via Azure Bastion (port 22)
-  Isolées du trafic Internet direct (Firewall block-by-default)
-  Cloud-init déjà exécuté (no re-run)

---

## 🔧 Variables critiques

Voir `variables.tf` pour liste complète. Les plus importantes :

| Variable          | Défaut           | ANSSI                         |
| ----------------- | ---------------- | ----------------------------- |
| `deploy_firewall` | `false`          | ✅ Passer à `true` en Phase 3 |
| `deploy_bastion`  | `false`          | ✅ Passer à `true` en Phase 3 |
| `deploy_waf`      | `true`           | ✅ Application Gateway WAF    |
| `vm_size`         | `Standard_B1s`   | ⚠️ FinOps (test only)         |
| `project_name`    | `cloudshield`    | —                             |
| `location`        | `francec entral` | —                             |

### ✅ IPs dynamiques (Terraform interpolation)

**Solution implémentée** : Les IPs des VMs sont passées via Terraform string interpolation dans le custom_data :

```terraform
# Dans vm-web cloud-init :
APP_HOST = "${azurerm_network_interface.nic_app.private_ip_address}"

# Dans vm-app cloud-init :
DB_HOST = "${azurerm_network_interface.nic_db.private_ip_address}"
```

**Avantage** :
-  Fonctionne quelle que soit l'IP assignée par Azure
-  Pas de hardcoding static (10.1.2.4, 10.2.1.4)
-  Production-ready
-  Terraform gère les dépendances (crée NICs d'abord, puis résout les IPs)

---

## 🔐 ANSSI Compliance Checklist

| Règle | Élément                  | Status | Fichier                         |
| ----- | ------------------------ | ------ | ------------------------------- |
| R9    | Comptes nominatifs       | ✅     | compute.tf (no root)            |
| R14   | Auth SSH Ed25519         | ✅     | ssh.tf (clé Ed25519)            |
| R14   | Bastion sans IP pub      | ✅     | bastion.tf                      |
| R19   | Deny-All NSG             | ✅     | security.tf (prio 4000)         |
| R22   | Egress Internet firewall | ✅     | firewall.tf (policy)            |
| R23   | Inspection inter-VNets   | ✅     | firewall.tf + routing.tf        |
| R25   | Logging centralisé       | ✅     | observability.tf (LAW)          |
| R28   | Bastion SSH rules        | ✅     | security.tf (port 22, prio 200) |
| R36   | Logs immutable           | ✅     | observability.tf (DCR + LAW)    |
| R37   | Alertes RT               | ✅     | observability.tf (Alert Rules)  |

---

## 🚨 Bugs fixes (09/04/2026)

### Fix #1 : ssh.tf — RSA 4096 → Ed25519

**Avant** : `algorithm = "RSA"` + `rsa_bits = 4096`
**Après** : `algorithm = "ED25519"`
**Raison** : ANSSI R14 recommande Ed25519

### Fix #2 : security.tf — NSG port 2221 → 22

**Avant** : `destination_port_range = "2221"`
**Après** : `destination_port_range = "22"`
**Raison** : Azure Bastion force toujours le port 22 (pas de redirection possible)

### Fix #3 : routing.tf — UDR conditionnelle

**Avant** : `azurerm_route_table` créée toujours
**Après** : `count = var.deploy_firewall ? 1 : 0`
**Raison** : Sans firewall, UDR → race condition cloud-init

### Fix #4 : compute.tf — IPs hardcodées (FIX ✅)

**Avant** : IPs statiques hardcodées en Python cloud-init
```python
APP_HOST = os.environ.get("APP_HOST", "10.1.2.4")  # ← Hardcodée
DB_HOST  = os.environ.get("DB_HOST", "10.2.1.4")   # ← Hardcodée
```

**Après** : Terraform string interpolation (IPs dynamiques)
```python
APP_HOST = "${azurerm_network_interface.nic_app.private_ip_address}"  # ✅ Terraform resolves
DB_HOST  = "${azurerm_network_interface.nic_db.private_ip_address}"   # ✅ Terraform resolves
```

**Raison** : Azure assigne les IPs dynamiquement → Terraform interpolation capture les adresses réelles
**Impact** : ✅ **Production-ready** — Fonctionne quelle que soit l'IP assignée par Azure

---

## 📊 Coûts (EUR/mois — base juillet 2026)

| Ressource      | Coût        | Notes                       |
| -------------- | ----------- | --------------------------- |
| Azure Firewall | 18,00 €     | Premium (policy-based)      |
| VMs (4x B1s)   | 10,50 €     | FinOps test size            |
| Log Analytics  | 9,20 €      | 5 GB/mois pay-as-you-go     |
| VPN Gateway    | 11,50 €     | P2S + BGP                   |
| WAF Policy     | 4,60 €      | Application Gateway WAF     |
| Storage + misc | 3,81 €      | Blobs + Backup + etc        |
| **TOTAL**      | **57,86 €** | Avec firewall + tout activé |

**Si `deploy_firewall=false`** : −18€ base (~39€/mois)

---

## ✅ Checklist avant production

- [ ] `deploy_firewall = true` + `deploy_bastion = true`
- [ ] Cloud-init status = "done" sur toutes les VMs
- [ ] Azure Monitor Data Collection Rules = ok (dans observability.tf)
- [ ] Log Analytics workspace reçoit logs (vérifier KQL queries)
- [ ] Alert Rules créées et fonctionnelles
- [ ] Firewall Policy = "Deny" par défaut (vérifier dans Azure Portal)
- [ ] NSG rules vérifiées (ASG references, pas d'IPs hardcodées)
- [ ] VPN P2S testé + BGP routes propagées
- [ ] SSH keys sauvegardées (Key Vault)
- [ ] tfstate backend chiffré (Azure Blob Storage + encryption)

---

## 🔗 Ressources

- **ANSSI CAD** : <https://www.anssi.gouv.fr/uploads/guide-cloud-azure.pdf>
- **Terraform Azure Provider** : <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs>
- **Azure Zero Trust** : <https://learn.microsoft.com/en-us/security/zero-trust/>
- **Repo GitHub** : <https://github.com/YnovOps-InfraGroup/NETWORK-TP-FINAL-CLOUDSHIELD>

---

**Dernière mise à jour** : 09/04/2026
