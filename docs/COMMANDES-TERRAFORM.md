# Commandes Terraform

## Déploiement complet

```bash
cd terraform/

# 1. Init (backend remote Storage Account)
terraform init

# 2. Valider la syntaxe
terraform validate

# 3. Formater
terraform fmt -recursive

# 4. Planifier — vérifier AVANT de dépenser
terraform plan -out=cloudshield.tfplan

# 5. Déployer (~30 min)
terraform apply cloudshield.tfplan

# 6. Outputs
terraform output
```

## Destruction (FinOps — chaque soir)

```bash
terraform destroy -auto-approve
```

## Déploiement phasé

### Phase 1 — Sans VPN (économie 0,76 €/h)

```hcl
# terraform.tfvars
deploy_vpn_gateways = false
```

### Phase 2 — Avec VPN (recette finale)

```hcl
deploy_vpn_gateways = true
```

## Structure des fichiers Terraform

```
terraform/
├── providers.tf           # AzureRM 4.x + backend remote
├── variables.tf           # Variables centralisées
├── locals.tf              # Naming, tags calculés
├── resource_groups.tf     # Resource Groups
├── network.tf             # VNets, Subnets, Peerings
├── routing.tf             # UDR — forced tunneling
├── security.tf            # NSGs, ASGs — Zero Trust
├── firewall.tf            # Azure Firewall + Firewall Policy
├── bastion.tf             # Azure Bastion Basic
├── vpn.tf                 # VPN Gateways + IPsec/BGP
├── compute.tf             # 4 VMs Linux B1s
├── waf.tf                 # Application Gateway WAF v2
├── paas.tf                # Storage, SQL, PE, DNS privées
├── observability.tf       # Log Analytics, AMA, alertes
├── outputs.tf             # Valeurs exportées
└── terraform.tfvars.template
```

## Commandes utiles

```bash
# Lister les ressources dans le state
terraform state list

# Voir une ressource spécifique
terraform state show azurerm_firewall.hub

# Rafraîchir
terraform refresh

# Cibler une ressource (debug)
terraform apply -target=azurerm_firewall.hub
```
