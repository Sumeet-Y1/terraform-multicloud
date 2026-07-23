output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "primary_blob_endpoint" {
  description = "Primary blob storage endpoint URL"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "container_names" {
  description = "Names of all created blob containers"
  value       = { for k, c in azurerm_storage_container.main : k => c.name }
}