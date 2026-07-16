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

resource "google_compute_instance" "main" {
  count        = var.instance_count
  name         = "${var.environment}-instance-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.network_tags

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    # No access_config block = no public IP (stays private, like AWS/Azure private subnet instances)
  }

  labels = {
    environment = var.environment
  }
}