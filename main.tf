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
  version                      = "9.5"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_firewall_rule" "postgres-srv" {
  name                = "AllowAzureServices"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  server_name         = azurerm_postgresql_server.postgres-srv.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_postgresql_database" "postgres-db" {
  name                = "postgres-db-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-maalsi.name
  server_name         = azurerm_postgresql_server.postgres-srv.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
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
    
  }
}