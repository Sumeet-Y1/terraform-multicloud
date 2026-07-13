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