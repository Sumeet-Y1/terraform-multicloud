variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region to deploy resources in"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone to deploy the instance in"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "machine_type" {
  description = "GCP machine type (equivalent to AWS instance type / Azure VM size)"
  type        = string
  default     = "e2-micro"
}

variable "subnet_id" {
  description = "Self link or ID of the subnet to attach the instance to"
  type        = string
}

variable "network_tags" {
  description = "Network tags for firewall targeting (e.g. web, app, database)"
  type        = list(string)
  default     = ["app"]
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}