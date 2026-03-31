# Commandes Azure CLI

## Authentification

```bash
az login
az account show --output table
az account set --subscription "SUBSCRIPTION_ID_REMOVED"
```

## Réseau

```bash
# Lister les VNets
az network vnet list -g rg-cloudshield-prod -o table

# Peerings
az network vnet peering list --vnet-name vnet-hub-cloudshield -g rg-cloudshield-prod -o table

# Effective Routes
az network nic show-effective-route-table --name nic-vm-web -g rg-cloudshield-prod -o table

# Effective Security Rules
az network nic list-effective-nsg --name nic-vm-web -g rg-cloudshield-prod
```

## VPN

```bash
# Status connexion
az network vpn-connection show --name cn-vpn-hub-to-onprem -g rg-cloudshield-prod \
  --query "{status:connectionStatus, protocol:connectionProtocol, bgp:enableBgp}"

# Routes BGP
az network vnet-gateway list-learned-routes --name vpngw-hub-cloudshield \
  -g rg-cloudshield-prod -o table
```

## Firewall

```bash
# Status
az network firewall show --name fw-hub-cloudshield -g rg-cloudshield-prod \
  --query "{state:provisioningState, threatIntel:threatIntelMode}"

# Règles
az network firewall policy rule-collection-group list \
  --policy-name fwpol-hub-cloudshield -g rg-cloudshield-prod -o table
```

## Bastion

```bash
# SSH via Bastion (vm-web)
az network bastion ssh --name bastion-cloudshield \
  -g rg-cloudshield-prod \
  --target-resource-id $(az vm show -g rg-cloudshield-prod -n vm-web --query id -o tsv) \
  --auth-type ssh-key --username azureuser --ssh-key ~/.ssh/id_ed25519
```

## Monitoring

```bash
# Log Analytics status
az monitor log-analytics workspace show --workspace-name law-cloudshield \
  -g rg-cloudshield-prod -o table

# KQL query
az monitor log-analytics query -w <workspace-id> \
  --analytics-query "Syslog | where TimeGenerated > ago(1h) | summarize count() by Computer"
```

## Private Endpoints

```bash
# Lister
az network private-endpoint list -g rg-cloudshield-prod -o table

# Test DNS (depuis vm-db via Bastion)
nslookup stcloudshielddata.blob.core.windows.net
```

## Coûts

```bash
# Consommation du jour
az consumption usage list --start-date 2026-03-31 --end-date 2026-04-01 -o table
```
