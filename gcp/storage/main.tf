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

# ---------- BUCKETS ----------
resource "google_storage_bucket" "main" {
  for_each      = var.buckets
  name          = "${var.bucket_prefix}-${each.key}"
  location      = var.region
  project       = var.project_id
  storage_class = var.storage_class

  versioning {
    enabled = each.value
  }

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  # Only the "logs" bucket gets lifecycle rules - transition to cheaper storage, then delete
  dynamic "lifecycle_rule" {
    for_each = each.key == "logs" ? [1] : []
    content {
      condition {
        age = var.logs_archive_days
      }
      action {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = each.key == "logs" ? [1] : []
    content {
      condition {
        age = var.logs_delete_days
      }
      action {
        type = "Delete"
      }
    }
  }

  labels = {
    environment = var.environment
    purpose     = each.key
  }
}

# ---------- IAM BINDING (grant read access to the data bucket) ----------
resource "google_storage_bucket_iam_member" "data_readers" {
  for_each = toset(var.reader_members)
  bucket   = google_storage_bucket.main["data"].name
  role     = "roles/storage.objectViewer"
  member   = each.value
}