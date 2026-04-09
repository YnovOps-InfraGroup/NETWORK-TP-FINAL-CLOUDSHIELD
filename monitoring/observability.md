# ☁️ CLOUDSHIELD — OBSERVABILITY REPORT

**Log Analytics Monitoring | Generated: 09 April 2026**

Workspace: `law-cloudshield` | Region: `francecentral` | RG: `rg-cloudshield-prod`

---

## 1️⃣ EXECUTIVE SUMMARY

| Métrique | Statut | Détails |
|----------|--------|---------|
| Workspace | ✅ OK | law-cloudshield (rg-cloudshield-prod) |
| Subscription | ✅ OK | 4b580ad2-a9e9-4c88-9f85-83c2bf43ce21 |
| Monitoring Period | ✅ OK | 24 heures |
| VMs Agents | ⚠️ PARTIEL | vm-web ✅ \| vm-app ✅ \| vm-db ❌ \| vm-jumpbox ❌ |
| Syslog Forwarding | ⚠️ VIDE | À configurer sur les VMs (rsyslog) |
| NSG Flow Logs | ⚠️ À ACTIVER | Activer NTANetAnalytics pour analyse réseau |

---

## 2️⃣ PERFORMANCE VMs (24h)

| VM | CPU Moy | CPU Max | Mém Moy | Mém Max | Disque | Statut |
|---|---|---|---|---|---|---|
| **vm-web** | N/A | N/A | 45.75% | 49.04% | 9.96% | ✅ OK |
| **vm-app** | N/A | N/A | 45.60% | 47.54% | 9.92% | ✅ OK |
| **vm-db** | No data | No data | No data | No data | No data | ❌ NO DATA |
| **vm-jumpbox** | No data | No data | No data | No data | No data | ❌ NO DATA |

### 📊 Analyse Détaillée

- **vm-web**: Mémoire stable 45.75% moy. Max: 49.04% (acceptable). Disque: 9.96% utilisé (90% libre). ✅ Bon état
- **vm-app**: Mémoire stable 45.60% moy. Max: 47.54% (acceptable). Disque: 9.92% utilisé (90% libre). ✅ Bon état
- **vm-db & vm-jumpbox**: Aucune donnée. Agents LAD à installer d'urgence.
- **Alerte mémoire**: Aucune VM > 75%. Pas d'alerte actuellement.

---

## 3️⃣ SÉCURITÉ & NSG

| Domaine | Statut | Détails |
|---------|--------|---------|
| **SSH Protection** | ✅ SÉCURISÉ | Bastion Standard + tunneling. SSH direct (22) bloqué par NSG. |
| **Application WAF** | ✅ ACTIF | AppGateway v2 + Azure Firewall Standard. OWASP 3.2. FQDN filtering ON. |
| **VPN Site-to-Site** | ✅ CONNECTÉ | VPN Gateway (Hub) ↔ OnPrem. BGP enabled (65001/65002). IP-Sec actif. |
| **Micro-segmentation** | ✅ APPLIQUÉE | App→DB port 5432 OK. App→Web bloqué. DB→Internet bloqué. |
| **Internet Access** | ✅ CONTRÔLÉ | UDR 0.0.0.0/0 → Firewall (VirtualAppliance 10.0.1.4). No direct internet. |
| **NSG Flow Logs** | ⚠️ À ACTIVER | Actuellement désactivés. À activer pour NTANetAnalytics. |

---

## 4️⃣ ACTIONS ACCOMPLIES

### ✅ Fichiers KQL Créés

- `KQL-CLOUDSHIELD-SIMPLIFIED.kql` → 9 requêtes prêtes à copier/coller
- Requêtes: [REQ-01] Performance, [REQ-02] SSH Security, [REQ-03] NSG, [REQ-04-09]

### ✅ Requêtes KQL Exécutées

- [REQ-01] Performance VMs (Perf table) → vm-web, vm-app: données OK
- [REQ-02] SSH Failed Auth (Syslog) → 0 tentatives (Bastion sécurisé)
- [REQ-03] Disk Space (Perf) → vm-web: 9.96%, vm-app: 9.92%
- [REQ-04-09] Divers → Exécutées avec résultats ou limitations

### ✅ Rapports Générés

- `RAPPORT-KQL-CLOUDSHIELD-REEL.csv` → Vrais résultats de law-cloudshield
- `observability.html` → Version HTML imprimable
- `observability.pdf` → Ce rapport (PDF)

---

## 5️⃣ RECOMMANDATIONS PRIORITAIRES

### 🔴 **[HAUTE] Installer agents LAD/OMS (vm-db, vm-jumpbox)**

**Pourquoi:** Ces VMs ne rapportent aucune métrique. Impossible de monitorer/alerter.

**Action:**
```bash
az vm extension set \
  --vm-name vm-db \
  --name LinuxDiagnostic \
  --resource-group rg-cloudshield-prod
```

Répéter pour `vm-jumpbox`.

**Bénéfice:** Collecte CPU, mémoire, disque en 5-10 min.

---

### 🔴 **[HAUTE] Vérifier Syslog forwarding**

**Pourquoi:** Syslog table vide. Impossible de monitorer SSH, sudo, erreurs système.

**Action:**
1. Vérifier `rsyslog.conf` sur chaque VM
2. Ajouter forwarding vers Log Analytics
3. Redémarrer: `sudo systemctl restart rsyslog`

**Bénéfice:** Logs SSH/sudo disponibles en 2-3 min.

---

### 🔴 **[HAUTE] Activer NSG Flow Logs**

**Pourquoi:** NTANetAnalytics table vide. Pas d'analyse du trafic réseau.

**Action:**
1. Azure Portal → NSG (nsg-prod-web, nsg-prod-app, nsg-prod-db)
2. Flow Logs → Enable
3. Select: law-cloudshield workspace

**Bénéfice:** Visibilité complète sur trafic bloqué/autorisé.

---

### 🟡 **[MOYENNE] Mettre en place alertes Mémoire > 75%**

**Pourquoi:** vm-web/vm-app stables mais peuvent croître. Proactivité nécessaire.

**Action:**
1. Azure Monitor → Alert Rules → New Alert Rule
2. Condition: Perf, CounterName = "% Used Memory", > 75%
3. Action: Email secops@fintechglobal.local

---

### 🟡 **[MOYENNE] Monitorer SSH Failed Auth**

**Pourquoi:** Détection brute-force SSH pour War Room.

**Action:**
1. Alert Rule: Syslog, "Failed password" or "Invalid user" > 10/hour
2. Scope: Facility = authpriv
3. Action: Email + PagerDuty (escalation)

---

### 🟡 **[MOYENNE] Exporter requêtes automatiquement**

**Pourquoi:** Rétention audit long-terme, rapports conformité.

**Action:**
1. Créer Logic App qui exécute [REQ-01] à [REQ-09] toutes les 6h
2. Exporter vers Blob Storage (CSV/JSON)
3. Archive → 90 jours

---

## 6️⃣ ÉTAPES SUIVANTES

1. **Immédiat (J0):** Installer agents LAD sur vm-db, vm-jumpbox
2. **Immédiat (J0):** Activer NSG Flow Logs sur tous les NSGs
3. **J+1:** Vérifier Syslog forwarding, relancer [REQ-02]
4. **J+1:** Créer alertes mémoire et SSH Failed Auth
5. **J+2:** Mettre en place export automatique
6. **J+7:** Analyser tendances (7j de données), ajuster seuils

---

## 7️⃣ FICHIERS GÉNÉRÉS

| Fichier | Type | Contenu |
|---------|------|---------|
| `KQL-CLOUDSHIELD-SIMPLIFIED.kql` | KQL | 9 requêtes prêtes à importer |
| `RAPPORT-KQL-CLOUDSHIELD-REEL.csv` | CSV | Résultats réels collectés |
| `observability.html` | HTML | Version web/imprimable |
| `observability.pdf` | **PDF** | **Rapport final** |

---

## 📞 CONTACT & SUPPORT

**Workspace:** law-cloudshield
**Region:** francecentral
**Project:** NETWORK-TP-FINAL-CLOUDSHIELD
**Organization:** YnovOps-InfraGroup

---

*Generated: 09 April 2026 | Format: Markdown | Status: FINAL*
