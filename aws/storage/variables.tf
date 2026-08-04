variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
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
  description = "Days before logs bucket objects transition to STANDARD_IA storage class"
  type        = number
  default     = 30
}

variable "logs_delete_days" {
  description = "Days before logs bucket objects are deleted entirely"
  type        = number
  default     = 90
}

variable "reader_arns" {
  description = "List of IAM principal ARNs granted read access to the data bucket"
  type        = list(string)
  default     = []
}
