output "vm_ids" {
  description = "IDs of the created VMs"
  value       = azurerm_linux_virtual_machine.main[*].id
}

output "vm_private_ips" {
  description = "Private IP addresses of the created VMs"
  value       = azurerm_network_interface.main[*].private_ip_address
}

output "nic_ids" {
  description = "IDs of the network interfaces"
  value       = azurerm_network_interface.main[*].id
}