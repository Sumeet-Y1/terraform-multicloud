terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------- INSTANCE TEMPLATE ----------
# Blueprint for every instance the MIG creates - similar to an AWS Launch Template
resource "google_compute_instance_template" "main" {
  name_prefix  = "${var.environment}-tmpl-"
  machine_type = var.machine_type
  tags         = var.network_tags

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = var.subnet_id
    # No access_config = no public IP, stays private
  }

  # Shielded VM - protects against rootkits/bootkits at the hypervisor level
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- HEALTH CHECK ----------
# The MIG uses this to detect and auto-replace unhealthy instances
resource "google_compute_health_check" "main" {
  name                = "${var.environment}-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 8080
    request_path = "/health"
  }
}

# ---------- MANAGED INSTANCE GROUP ----------
resource "google_compute_region_instance_group_manager" "main" {
  name               = "${var.environment}-mig"
  region             = var.region
  base_instance_name = "${var.environment}-instance"

  version {
    instance_template = google_compute_instance_template.main.id
  }

  target_size = var.enable_autoscaling ? null : var.target_replicas

  auto_healing_policies {
    health_check      = google_compute_health_check.main.id
    initial_delay_sec = 60
  }

  named_port {
    name = "http"
    port = 8080
  }
}

# ---------- AUTOSCALER ----------
resource "google_compute_region_autoscaler" "main" {
  count  = var.enable_autoscaling ? 1 : 0
  name   = "${var.environment}-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.main.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = 60

    cpu_utilization {
      target = var.cpu_target_utilization
    }
  }
}