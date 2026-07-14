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

# Network Interface — Azure VMs need an explicit NIC resource (unlike AWS, where it's implicit)
resource "azurerm_network_interface" "main" {
  count               = var.vm_count
  name                = "${var.environment}-nic-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = var.environment
  }
}

# Attach the NIC to Application Security Groups (for tiered NSG rules to apply)
resource "azurerm_network_interface_application_security_group_association" "main" {
  count                         = length(var.application_security_group_ids) > 0 ? var.vm_count : 0
  network_interface_id         = azurerm_network_interface.main[count.index].id
  application_security_group_id = var.application_security_group_ids[0]
}

# Linux VM
resource "azurerm_linux_virtual_machine" "main" {
  count               = var.vm_count
  name                = "${var.environment}-vm-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.main[count.index].id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    Environment = var.environment
  }
}