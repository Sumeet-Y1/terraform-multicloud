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

resource "google_storage_bucket" "main" {
  name          = var.bucket_name
  location      = var.region
  project       = var.project_id
  storage_class = var.storage_class

  versioning {
    enabled = var.enable_versioning
  }

  # Secure by default — blocks public access at the bucket level
  public_access_prevention = "enforced"

  # Encryption is automatic with Google-managed keys by default, no extra resource needed

  uniform_bucket_level_access = true

  labels = {
    environment = var.environment
  }
}