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

resource "google_compute_network" "main" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
}

# ---------- SUBNETS ----------
resource "google_compute_subnetwork" "public" {
  name          = "${var.environment}-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata              = "INCLUDE_ALL_METADATA"
    }
  }
}

resource "google_compute_subnetwork" "private" {
  name                      = "${var.environment}-private-subnet"
  ip_cidr_range             = var.private_subnet_cidr
  region                    = var.region
  network                   = google_compute_network.main.id
  private_ip_google_access  = true

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata              = "INCLUDE_ALL_METADATA"
    }
  }
}

resource "google_compute_subnetwork" "database" {
  name                     = "${var.environment}-database-subnet"
  ip_cidr_range            = var.database_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata              = "INCLUDE_ALL_METADATA"
    }
  }
}

# ---------- CLOUD ROUTER + NAT ----------
resource "google_compute_router" "main" {
  name    = "${var.environment}-router"
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = "${var.environment}-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ---------- FIREWALL RULES ----------
# Priorities matter in GCP - lower number = evaluated first. Default is 1000.

resource "google_compute_firewall" "allow_web" {
  name     = "${var.environment}-allow-web"
  network  = google_compute_network.main.id
  priority = 900

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_app_from_web" {
  name     = "${var.environment}-allow-app-from-web"
  network  = google_compute_network.main.id
  priority = 900

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_tags = ["web"]
  target_tags = ["app"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_db_from_app" {
  name     = "${var.environment}-allow-db-from-app"
  network  = google_compute_network.main.id
  priority = 900

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["app"]
  target_tags = ["database"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Bastion host access — SSH only from trusted IP ranges, never 0.0.0.0/0
resource "google_compute_firewall" "allow_bastion_ssh" {
  name     = "${var.environment}-allow-bastion-ssh"
  network  = google_compute_network.main.id
  priority = 800 # evaluated before the general rules above

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.bastion_allowed_ip_ranges
  target_tags   = ["bastion"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow instances tagged "app" to be reached via SSH ONLY from the bastion, never externally
resource "google_compute_firewall" "allow_ssh_from_bastion" {
  name     = "${var.environment}-allow-ssh-from-bastion"
  network  = google_compute_network.main.id
  priority = 850

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["bastion"]
  target_tags = ["app", "database"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Explicit deny-all for anything not matched above (GCP denies by default anyway,
# but an explicit low-priority deny makes the intent visible for anyone reading the config)
resource "google_compute_firewall" "deny_all_ingress" {
  name     = "${var.environment}-deny-all-ingress"
  network  = google_compute_network.main.id
  priority = 65534
  direction = "INGRESS"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}