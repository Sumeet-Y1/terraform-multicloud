variable "resource_group_name" {
  description = "Name of the resource group to deploy into"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources in"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vm_size" {
  description = "Azure VM size (equivalent to AWS instance type)"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to attach the VM's NIC to (typically a private/app subnet)"
  type        = string
}

variable "application_security_group_ids" {
  description = "List of Application Security Group IDs to associate with the VM's NIC"
  type        = list(string)
  default     = []
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}