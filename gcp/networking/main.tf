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

# VPC — GCP VPCs are global, not tied to a single region (unlike AWS VPC / Azure VNet)
resource "google_compute_network" "main" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
}

# ---------- SUBNETS ----------
# Note: GCP subnets are regional resources, even though the VPC itself is global

resource "google_compute_subnetwork" "public" {
  name          = "${var.environment}-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.environment}-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  # Allows resources in this subnet to reach Google APIs/services without a public IP
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "database" {
  name          = "${var.environment}-database-subnet"
  ip_cidr_range = var.database_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  private_ip_google_access = true
}

# ---------- CLOUD ROUTER + NAT (for private subnet outbound internet) ----------
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
}

# ---------- FIREWALL RULES ----------
# GCP firewall rules are attached to the VPC network, not to a subnet or instance directly.
# Targeting is done via tags (like Azure's ASGs, but simpler - just string labels)

resource "google_compute_firewall" "allow_web" {
  name    = "${var.environment}-allow-web"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "allow_app_from_web" {
  name    = "${var.environment}-allow-app-from-web"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_tags = ["web"]
  target_tags = ["app"]
}

resource "google_compute_firewall" "allow_db_from_app" {
  name    = "${var.environment}-allow-db-from-app"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["app"]
  target_tags = ["database"]
}

# Deny-all is implicit in GCP — no rule needed. Only explicitly allowed traffic gets through.