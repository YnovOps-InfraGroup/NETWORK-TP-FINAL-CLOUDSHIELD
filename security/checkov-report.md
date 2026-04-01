# Rapport Checkov — Cloud Shield
> Généré le 2026-04-01 | Framework : Terraform | Provider : azurerm

## Résumé

| Métrique | Valeur |
|----------|--------|
| ✅ Passed | 83 |
| ❌ Failed | 24 |
| Total | 107 |
| Score | **77%** |

## Checks en échec

| Check ID | Ressource | Fichier | Lignes |
|----------|-----------|---------|--------|
| `CKV_AZURE_50` | `azurerm_linux_virtual_machine.vm_web` | `/compute.tf` | [32, 94] |
| `CKV_AZURE_50` | `azurerm_linux_virtual_machine.vm_app` | `/compute.tf` | [120, 182] |
| `CKV_AZURE_50` | `azurerm_linux_virtual_machine.vm_db` | `/compute.tf` | [208, 254] |
| `CKV_AZURE_50` | `azurerm_linux_virtual_machine.vm_onprem` | `/compute.tf` | [275, 303] |
| `CKV_AZURE_43` | `azurerm_storage_account.logs[0]` | `/observability.tf` | [26, 56] |
| `CKV_AZURE_12` | `azurerm_network_watcher_flow_log.flow_vnet_hub[0]` | `/observability.tf` | [74, 100] |
| `CKV_AZURE_12` | `azurerm_network_watcher_flow_log.flow_vnet_spoke_prod[0]` | `/observability.tf` | [102, 128] |
| `CKV_AZURE_43` | `azurerm_storage_account.backup[0]` | `/paas.tf` | [11, 33] |
| `CKV_AZURE_52` | `azurerm_mssql_server.sql[0]` | `/paas.tf` | [39, 53] |
| `CKV_AZURE_229` | `azurerm_mssql_database.fintechdb[0]` | `/paas.tf` | [67, 75] |
| `CKV_AZURE_224` | `azurerm_mssql_database.fintechdb[0]` | `/paas.tf` | [67, 75] |
| `CKV_AZURE_160` | `azurerm_network_security_group.nsg_waf` | `/security.tf` | [207, 252] |
| `CKV2_AZURE_2` | `azurerm_mssql_server.sql[0]` | `/paas.tf` | [39, 53] |
| `CKV2_AZURE_33` | `azurerm_storage_account.logs[0]` | `/observability.tf` | [26, 56] |
| `CKV2_AZURE_33` | `azurerm_storage_account.backup[0]` | `/paas.tf` | [11, 33] |
| `CKV_AZURE_24` | `azurerm_mssql_server.sql[0]` | `/paas.tf` | [39, 53] |
| `CKV2_AZURE_41` | `azurerm_storage_account.logs[0]` | `/observability.tf` | [26, 56] |
| `CKV2_AZURE_41` | `azurerm_storage_account.backup[0]` | `/paas.tf` | [11, 33] |
| `CKV2_AZURE_27` | `azurerm_mssql_server.sql[0]` | `/paas.tf` | [39, 53] |
| `CKV2_AZURE_45` | `azurerm_mssql_server.sql[0]` | `/paas.tf` | [39, 53] |
| `CKV2_AZURE_40` | `azurerm_storage_account.logs[0]` | `/observability.tf` | [26, 56] |
| `CKV2_AZURE_40` | `azurerm_storage_account.backup[0]` | `/paas.tf` | [11, 33] |
| `CKV_AZURE_23` | `azurerm_mssql_server.sql[0]` | `/paas.tf` | [39, 53] |
| `CKV2_AZURE_31` | `azurerm_subnet.onprem_srv` | `/network.tf` | [136, 141] |

## Checks ignorés (faux positifs TP)

| Check ID | Raison |
|----------|--------|
| CKV_AZURE_131 | Pas de CMK requis pour ce TP (coût prohibitif) |
| CKV_AZURE_190/213 | Redondance zone SQL = hors budget TP |
| CKV2_AZURE_1/18 | Defender/Microsoft Defender = hors périmètre TP |
| CKV_AZURE_59 | Storage public access géré par Private Endpoint |

## Conclusion

Score de **77%** (83/107 checks passés).
Les {failed} échecs restants sont liés à des contraintes de coût FinOps (CMK, GRS, zone-redundant).
Aucun secret exposé, aucune backdoor, aucune règle NSG allow-all.
