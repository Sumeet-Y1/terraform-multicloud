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

variable "containers" {
  description = "Map of blob containers to create: key = container name, value = access type"
  type        = map(string)
  default = {
    "data"    = "private"
    "logs"    = "private"
    "backups" = "private"
  }
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access this storage account via network rules (empty = allow all, not recommended for prod)"
  type        = list(string)
  default     = []
}

variable "log_archive_days" {
  description = "Number of days after which blobs in the 'logs' container move to cool storage"
  type        = number
  default     = 30
}

variable "log_delete_days" {
  description = "Number of days after which blobs in the 'logs' container are deleted entirely"
  type        = number
  default     = 90
}

variable "log_analytics_workspace_id" {
  description = "Optional Log Analytics Workspace ID for diagnostic logging (leave empty to skip)"
  type        = string
  default     = ""
}