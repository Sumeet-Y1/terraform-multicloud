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

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.2.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private (app) subnet"
  type        = string
  default     = "10.2.11.0/24"
}

variable "database_subnet_cidr" {
  description = "CIDR block for the database subnet"
  type        = string
  default     = "10.2.21.0/24"
}

variable "bastion_allowed_ip_ranges" {
  description = "CIDR ranges allowed to SSH into the bastion host (e.g. your office/home IP, not 0.0.0.0/0)"
  type        = list(string)
  default     = ["203.0.113.0/24"] # placeholder - replace with a real trusted range
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs on subnets for traffic visibility"
  type        = bool
  default     = true
}