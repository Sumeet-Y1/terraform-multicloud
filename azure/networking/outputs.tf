output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, keyed by name suffix"
  value       = { for k, s in azurerm_subnet.public : k => s.id }
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, keyed by name suffix"
  value       = { for k, s in azurerm_subnet.private : k => s.id }
}

output "database_subnet_ids" {
  description = "IDs of the database subnets, keyed by name suffix"
  value       = { for k, s in azurerm_subnet.database : k => s.id }
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = azurerm_nat_gateway.main.id
}

output "web_asg_id" {
  description = "ID of the web tier application security group"
  value       = azurerm_application_security_group.web.id
}

output "app_asg_id" {
  description = "ID of the app tier application security group"
  value       = azurerm_application_security_group.app.id
}

output "database_asg_id" {
  description = "ID of the database tier application security group"
  value       = azurerm_application_security_group.database.id
}