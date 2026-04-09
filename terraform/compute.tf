# ============================================================
# COMPUTE — VMs Linux (Web, App, DB, OnPrem)
# ANSSI R14 : Auth SSH par clé Ed25519, zéro IP publique
# ANSSI R9 : Comptes nominatifs, pas de root
# ============================================================

# ═══════════════════════════════════════════════════════════════
# VM-WEB — Tier 1 Présentation (Flask app)
# Subnet : snet-prod-web | ASG : asg-web
# ═══════════════════════════════════════════════════════════════

resource "azurerm_network_interface" "nic_web" {
  name                = "nic-vm-web"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig-web"
    subnet_id                     = azurerm_subnet.prod_web.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Association NIC → ASG (Exigence 3c : pas d'IP statiques dans les règles)
resource "azurerm_network_interface_application_security_group_association" "nic_web_asg" {
  network_interface_id          = azurerm_network_interface.nic_web.id
  application_security_group_id = azurerm_application_security_group.asg_web.id
}

resource "azurerm_linux_virtual_machine" "vm_web" {
  name                = "vm-web"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username

  network_interface_ids = [azurerm_network_interface.nic_web.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm_ssh.public_key_openssh # fix(ssh): root cause #3 — clé auto-générée
  }

  os_disk {
    name                 = "osdisk-vm-web"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Cloud-init : Flask application web
  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: false
    packages:
      - python3-pip
      - python3-venv
    runcmd:
      - pip3 install flask requests --break-system-packages
      - mkdir -p /opt/webapp
      - |
        cat > /opt/webapp/app.py << 'PYEOF'
        from flask import Flask
        import os, socket

        app = Flask(__name__)
        APP_HOST = os.environ.get("APP_HOST", "10.1.2.4")

        @app.route("/")
        def index():
            return f"<h1>FinTech Global - Cloud Shield</h1><p>VM: {socket.gethostname()}</p>", 200

        @app.route("/health")
        def health():
            return "OK", 200

        if __name__ == "__main__":
            app.run(host="0.0.0.0", port=80)
        PYEOF
      - nohup python3 /opt/webapp/app.py &
  CLOUDINIT
  )

  tags = var.tags
}

# ═══════════════════════════════════════════════════════════════
# VM-APP — Tier 2 Traitement (API Flask)
# Subnet : snet-prod-app | ASG : asg-app
# ═══════════════════════════════════════════════════════════════

resource "azurerm_network_interface" "nic_app" {
  name                = "nic-vm-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig-app"
    subnet_id                     = azurerm_subnet.prod_app.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_network_interface_application_security_group_association" "nic_app_asg" {
  network_interface_id          = azurerm_network_interface.nic_app.id
  application_security_group_id = azurerm_application_security_group.asg_app.id
}

resource "azurerm_linux_virtual_machine" "vm_app" {
  name                = "vm-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username

  network_interface_ids = [azurerm_network_interface.nic_app.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm_ssh.public_key_openssh # fix(ssh): root cause #3 — clé auto-générée
  }

  os_disk {
    name                 = "osdisk-vm-app"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Cloud-init : API backend (port 8080)
  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: false
    packages:
      - python3-pip
      - python3-venv
    runcmd:
      - pip3 install flask psycopg2-binary --break-system-packages
      - mkdir -p /opt/appapi
      - |
        cat > /opt/appapi/api.py << 'PYEOF'
        from flask import Flask, jsonify
        import os, socket

        app = Flask(__name__)
        DB_HOST = os.environ.get("DB_HOST", "10.2.1.4")

        @app.route("/api/health")
        def health():
            return jsonify({"status": "ok", "host": socket.gethostname()}), 200

        @app.route("/api/process")
        def process():
            return jsonify({"result": "payment_processed", "db_host": DB_HOST}), 200

        if __name__ == "__main__":
            app.run(host="0.0.0.0", port=8080)
        PYEOF
      - nohup python3 /opt/appapi/api.py &
  CLOUDINIT
  )

  tags = var.tags
}

# ═══════════════════════════════════════════════════════════════
# VM-DB — Tier 3 Stockage (PostgreSQL, CDE PCI-DSS)
# Subnet : snet-data-db | ASG : asg-db
# ═══════════════════════════════════════════════════════════════

resource "azurerm_network_interface" "nic_db" {
  name                = "nic-vm-db"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig-db"
    subnet_id                     = azurerm_subnet.data_db.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_network_interface_application_security_group_association" "nic_db_asg" {
  network_interface_id          = azurerm_network_interface.nic_db.id
  application_security_group_id = azurerm_application_security_group.asg_db.id
}

resource "azurerm_linux_virtual_machine" "vm_db" {
  name                = "vm-db"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username

  network_interface_ids = [azurerm_network_interface.nic_db.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm_ssh.public_key_openssh # fix(ssh): root cause #3 — clé auto-générée
  }

  os_disk {
    name                 = "osdisk-vm-db"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Cloud-init : PostgreSQL
  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - postgresql
      - postgresql-contrib
    runcmd:
      - systemctl enable postgresql
      - systemctl start postgresql
      - sudo -u postgres psql -c "CREATE USER appuser WITH PASSWORD '${var.db_password}';"
      - sudo -u postgres psql -c "CREATE DATABASE fintechdb OWNER appuser;"
      - echo "host all appuser 10.1.2.0/24 md5" >> /etc/postgresql/*/main/pg_hba.conf
      - sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
      - systemctl restart postgresql
  CLOUDINIT
  )

  tags = var.tags
}

# ═══════════════════════════════════════════════════════════════
# VM-ONPREM — Simulation site de Lyon
# Subnet : snet-onprem-srv
# ═══════════════════════════════════════════════════════════════

resource "azurerm_network_interface" "nic_onprem" {
  name                = "nic-vm-onprem"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig-onprem"
    subnet_id                     = azurerm_subnet.onprem_srv.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm_onprem" {
  name                = "vm-onprem"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username

  network_interface_ids = [azurerm_network_interface.nic_onprem.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm_ssh.public_key_openssh # fix(ssh): root cause #3 — clé auto-générée
  }

  os_disk {
    name                 = "osdisk-vm-onprem"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = var.tags
}

# ═══════════════════════════════════════════════════════════════
# AUTO-SHUTDOWN — FinOps : arrêt automatique quotidien 18h-8h (12h OFF/24h)
# ═══════════════════════════════════════════════════════════════

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_web" {
  virtual_machine_id    = azurerm_linux_virtual_machine.vm_web.id
  location              = azurerm_resource_group.main.location
  enabled               = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "Romance Standard Time"

  notification_settings {
    enabled = false
  }

  tags = var.tags
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_app" {
  virtual_machine_id    = azurerm_linux_virtual_machine.vm_app.id
  location              = azurerm_resource_group.main.location
  enabled               = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "Romance Standard Time"

  notification_settings {
    enabled = false
  }

  tags = var.tags
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_db" {
  virtual_machine_id    = azurerm_linux_virtual_machine.vm_db.id
  location              = azurerm_resource_group.main.location
  enabled               = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "Romance Standard Time"

  notification_settings {
    enabled = false
  }

  tags = var.tags
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_onprem" {
  virtual_machine_id    = azurerm_linux_virtual_machine.vm_onprem.id
  location              = azurerm_resource_group.main.location
  enabled               = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "Romance Standard Time"

  notification_settings {
    enabled = false
  }

  tags = var.tags
}
