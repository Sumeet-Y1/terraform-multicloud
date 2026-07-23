terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  min_tls_version                = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = {
    Environment = var.environment
  }
}

# ---------- CONTAINERS ----------
resource "azurerm_storage_container" "main" {
  for_each              = var.containers
  name                  = each.key
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value
}

# ---------- NETWORK RULES ----------
# Restrict storage account access to specific subnets instead of the whole internet
resource "azurerm_storage_account_network_rules" "main" {
  storage_account_id = azurerm_storage_account.main.id

  default_action             = length(var.allowed_subnet_ids) > 0 ? "Deny" : "Allow"
  virtual_network_subnet_ids = var.allowed_subnet_ids
  bypass                      = ["AzureServices"]
}

# ---------- LIFECYCLE MANAGEMENT ----------
# Auto-archive and auto-delete old logs to save cost, common in real setups
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "logs-lifecycle"
    enabled = true

    filters {
      prefix_match = ["logs/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = var.log_archive_days
        delete_after_days_since_modification_greater_than = var.log_delete_days
      }
    }
  }

  depends_on = [azurerm_storage_container.main]
}

# ---------- DIAGNOSTIC LOGGING ----------
# Sends storage account activity/metrics to a Log Analytics workspace if provided
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "${var.environment}-storage-diagnostics"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "Transaction"
  }
}