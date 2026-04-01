#!/bin/bash
# ============================================================
# Initialisation du Backend Remote Azure pour Cloud Shield
# Migre le state Terraform depuis local vers stoagreg3sr
# ============================================================

set -e

echo "🔄 Initialisation du backend remote Azure..."

# Créer la structure .terraform si elle n'existe pas
mkdir -p .terraform

# Réinitialiser avec reconfiguration
echo "   → terraform init -reconfigure..."
terraform init -reconfigure -backend=true

echo ""
echo "✅ Backend configuré avec succès!"
echo ""
echo "📍 Emplacement du state :"
echo "   • Storage Account : stoagreg3sr"
echo "   • Container       : tfstate"
echo "   • Blob            : cloudshield/terraform.tfstate"
echo ""
echo "🔒 Lock File           : .terraform/terraform.tfstate"
echo "ℹ️  À committer         : .terraform.lock.hcl, .gitignore"
echo "❌ À NE PAS committer  : .terraform/ (sauf .terraform.lock.hcl)"
echo ""
