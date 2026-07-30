variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "public_subnets" {
  description = "Map of public subnets: key = AZ suffix, value = CIDR block"
  type        = map(string)
  default = {
    "a" = "10.0.1.0/24"
    "b" = "10.0.2.0/24"
    "c" = "10.0.3.0/24"
  }
}

variable "private_subnets" {
  description = "Map of private (app-tier) subnets: key = AZ suffix, value = CIDR block"
  type        = map(string)
  default = {
    "a" = "10.0.11.0/24"
    "b" = "10.0.12.0/24"
    "c" = "10.0.13.0/24"
  }
}

variable "database_subnets" {
  description = "Map of database-tier subnets: key = AZ suffix, value = CIDR block"
  type        = map(string)
  default = {
    "a" = "10.0.21.0/24"
    "b" = "10.0.22.0/24"
    "c" = "10.0.23.0/24"
  }
}

variable "bastion_allowed_cidrs" {
  description = "CIDR ranges allowed to SSH into the bastion host (never use 0.0.0.0/0 in real usage)"
  type        = list(string)
  default     = ["203.0.113.0/24"] # placeholder - replace with your real trusted IP range
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs for traffic visibility"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC flow logs in CloudWatch"
  type        = number
  default     = 30
}