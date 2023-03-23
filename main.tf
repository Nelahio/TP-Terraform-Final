terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.6.0"
    }
  }
  backend "azurerm" {
    
  }
}

provider "azurerm" {
  # Configuration options
  features {
    
  }
}

# Database
resource "azurerm_postgresql_server" "postgres-srv" {
  name                = "postgres-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg-maalsi.location
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = data.azurerm_key_vault_secret.postgres-login.value
  administrator_login_password = data.azurerm_key_vault_secret.postgres-password.value
  version                      = "11"
  ssl_enforcement_enabled      = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}

resource "azurerm_postgresql_firewall_rule" "postgres-srv" {
  name                = "AllowAzureServices"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  server_name         = azurerm_postgresql_server.postgres-srv.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Web App
resource "azurerm_service_plan" "app-plan" {
  name                = "plan-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  location            = data.azurerm_resource_group.rg-maalsi.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "web-app" {
  name                = "web-app-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  location            = azurerm_service_plan.app-plan.location
  service_plan_id     = azurerm_service_plan.app-plan.id

  site_config {
    application_stack {
      node_version = "16-lts"
    }
  }
  app_settings = {
    "PORT" = var.port,
    "DB_HOST" = azurerm_postgresql_server.postgres-srv.fqdn,
    "DB_USERNAME" = "${data.azurerm_key_vault_secret.postgres-login.value}@${azurerm_postgresql_server.postgres-srv.name}"
    "DB_PASSWORD" = data.azurerm_key_vault_secret.postgres-password.value,
    "DB_DATABASE" = var.db_database,
    "DB_DAILECT" = var.db_dialect,
    "DB_PORT" = var.db_port,
    "ACCESS_TOKEN_SECRET" = data.azurerm_key_vault_secret.access-token.value,
    "REFRESH_TOKEN_SECRET" = data.azurerm_key_vault_secret.refresh-token.value,
    "ACCESS_TOKEN_EXPIRY" = var.access-token-expiry,
    "REFRESH_TOKEN_EXPIRY" = var.refresh-token-expiry,
    "REFRESH_TOKEN_COOKIE_NAME" = var.refresh-token-cookie-name,
  }
}

resource "azurerm_container_group" "pgadmin" {
  name                = "aci-pgadmin-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg-maalsi.location
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  ip_address_type     = "public"
  dns_name_label      = "aci-label"
  os_type             = "Linux"

  container {
    name   = "pgadmin"
    image  = "dpage/pgadmin4:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
    environment_variables = {
      "PGADMIN_DEFAULT_EMAIL" = data.azurerm_key_vault_secret.pgadmin-email.value
      "PGADMIN_DEFAULT_PASSWORD" = data.azurerm_key_vault_secret.pgadmin-password.value
    }
  }  
}