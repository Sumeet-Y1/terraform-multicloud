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

variable "public_subnets" {
  description = "Map of public subnets: key = name suffix, value = CIDR block"
  type        = map(string)
  default = {
    "a" = "10.1.1.0/24"
  }
}

variable "private_subnets" {
  description = "Map of private (app) subnets: key = name suffix, value = CIDR block"
  type        = map(string)
  default = {
    "a" = "10.1.11.0/24"
  }
}

variable "database_subnets" {
  description = "Map of database subnets: key = name suffix, value = CIDR block"
  type        = map(string)
  default = {
    "a" = "10.1.21.0/24"
  }
}

variable "bastion_subnet_cidr" {
  description = "CIDR for the AzureBastionSubnet (must be named exactly this, min /26)"
  type        = string
  default     = "10.1.250.0/26"
}

variable "enable_flow_logs" {
  description = "Enable NSG flow logs for traffic visibility"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Number of days to retain NSG flow logs"
  type        = number
  default     = 30
}

variable "storage_account_id" {
  description = "Storage account ID for flow logs and private endpoint (optional, leave empty to skip)"
  type        = string
  default     = ""
}