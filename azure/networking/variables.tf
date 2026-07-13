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

variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnets" {
  description = "Map of subnets: key = subnet name, value = CIDR block"
  type        = map(string)
  default = {
    "public"  = "10.1.1.0/24"
    "private" = "10.1.2.0/24"
    "database" = "10.1.3.0/24"
  }
}