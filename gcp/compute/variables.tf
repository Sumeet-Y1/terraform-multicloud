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
  description = "GCP zone for the health check region setting"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-micro"
}

variable "subnet_id" {
  description = "Self link or ID of the subnet to attach instances to"
  type        = string
}

variable "network_tags" {
  description = "Network tags for firewall targeting"
  type        = list(string)
  default     = ["app"]
}

variable "min_replicas" {
  description = "Minimum number of instances in the managed instance group"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of instances in the managed instance group"
  type        = number
  default     = 3
}

variable "target_replicas" {
  description = "Target/desired number of instances (used when autoscaling is disabled)"
  type        = number
  default     = 2
}

variable "enable_autoscaling" {
  description = "Enable autoscaling based on CPU utilization"
  type        = bool
  default     = true
}

variable "cpu_target_utilization" {
  description = "Target CPU utilization for autoscaling (0.0 to 1.0)"
  type        = number
  default     = 0.6
}