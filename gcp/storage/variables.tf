variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region to deploy resources in"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "bucket_prefix" {
  description = "Prefix for bucket names (final name = prefix-purpose, must be globally unique)"
  type        = string
}

variable "storage_class" {
  description = "Default storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"
}

variable "buckets" {
  description = "Map of buckets to create: key = purpose suffix, value = enable versioning"
  type        = map(bool)
  default = {
    "data"    = true
    "logs"    = false
    "backups" = true
  }
}

variable "logs_archive_days" {
  description = "Days before logs bucket objects move to Nearline storage class"
  type        = number
  default     = 30
}

variable "logs_delete_days" {
  description = "Days before logs bucket objects are deleted entirely"
  type        = number
  default     = 90
}

variable "reader_members" {
  description = "List of members (e.g. 'group:devs@company.com') granted read access to the data bucket"
  type        = list(string)
  default     = []
}