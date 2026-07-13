output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "IDs of the subnets, keyed by subnet name"
  value       = { for k, s in azurerm_subnet.main : k => s.id }
}

output "nsg_ids" {
  description = "IDs of the network security groups, keyed by subnet name"
  value       = { for k, n in azurerm_network_security_group.main : k => n.id }
}