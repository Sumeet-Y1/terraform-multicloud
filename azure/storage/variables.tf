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

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, lowercase, 3-24 chars, no special characters)"
  type        = string
}

variable "container_name" {
  description = "Name of the blob container"
  type        = string
  default     = "data"
}

variable "account_tier" {
  description = "Performance tier of the storage account (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication strategy (LRS, GRS, ZRS, RAGRS)"
  type        = string
  default     = "LRS"
}