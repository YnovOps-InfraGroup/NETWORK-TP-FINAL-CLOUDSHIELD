# ============================================================
# SSH Keys — Génération automatique + stockage Key Vault
# ANSSI R14 : Authentification par clé, sans mot de passe
# fix(ssh): root cause #3 — authorized_keys vide sur VMs
#
# Architecture :
#   tls_private_key → azurerm_key_vault_secret (clé privée)
#   tls_private_key.public_key_openssh → admin_ssh_key des VMs
# ============================================================

# ── Génération de la paire de clés SSH (Ed25519) — ANSSI R14 ────────────────────────────
resource "tls_private_key" "vm_ssh" {
  algorithm = "ED25519"
}

# ── Référence au Key Vault existant ─────────────────────────────────────────
data "azurerm_key_vault" "core" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
}

# ── Stockage de la clé privée dans Key Vault ────────────────────────────────
resource "azurerm_key_vault_secret" "vm_ssh_private_key" {
  name         = "ssh-vm-${var.project_name}"
  value        = tls_private_key.vm_ssh.private_key_openssh
  key_vault_id = data.azurerm_key_vault.core.id
  content_type = "text/plain"
  tags         = var.tags
}

# ── Stockage de la clé publique dans Key Vault (référence) ──────────────────
resource "azurerm_key_vault_secret" "vm_ssh_public_key" {
  name         = "ssh-vm-${var.project_name}-pub"
  value        = tls_private_key.vm_ssh.public_key_openssh
  key_vault_id = data.azurerm_key_vault.core.id
  content_type = "text/plain"
  tags         = var.tags
}
