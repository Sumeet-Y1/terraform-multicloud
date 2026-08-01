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
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

resource "google_compute_subnetwork" "private" {
  name                     = "${var.environment}-private-subnet"
  ip_cidr_range            = var.private_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
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
      metadata             = "INCLUDE_ALL_METADATA"
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

# ---------- PRIVATE SERVICE CONNECT (GCS access without internet) ----------
# Reserves an internal IP range for Google APIs, then routes private-subnet traffic
# to Google services (like Cloud Storage) entirely within Google's network.
resource "google_compute_global_address" "private_service_connect" {
  name          = "${var.environment}-psc-ip-range"
  purpose       = "PRIVATE_SERVICE_CONNECT"
  address_type  = "INTERNAL"
  address       = "10.2.100.0"
  prefix_length = 24
  network       = google_compute_network.main.id
}

resource "google_compute_global_forwarding_rule" "private_service_connect" {
  name                  = "${var.environment}-psc-endpoint"
  target                = "all-apis"
  network               = google_compute_network.main.id
  ip_address            = google_compute_global_address.private_service_connect.id
  load_balancing_scheme = ""
}

# ---------- FIREWALL RULES ----------
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

resource "google_compute_firewall" "allow_bastion_ssh" {
  name     = "${var.environment}-allow-bastion-ssh"
  network  = google_compute_network.main.id
  priority = 800

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

resource "google_compute_firewall" "deny_all_ingress" {
  name      = "${var.environment}-deny-all-ingress"
  network   = google_compute_network.main.id
  priority  = 65534
  direction = "INGRESS"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

# ---------- CLOUD ARMOR (WAF / DDoS protection for the web tier) ----------
resource "google_compute_security_policy" "web" {
  name = "${var.environment}-web-armor-policy"

  # Default rule - allow everything not explicitly matched below
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }

  # Rate limiting - throttle clients exceeding the threshold (basic DDoS mitigation)
  rule {
    action   = "throttle"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = var.rate_limit_threshold
        interval_sec = 60
      }
    }
    description = "Rate limit per client IP"
  }

  # Geo-blocking - deny specific countries if configured
  dynamic "rule" {
    for_each = length(var.blocked_countries) > 0 ? [1] : []
    content {
      action   = "deny(403)"
      priority = "900"
      match {
        expr {
          expression = "origin.region_code in ${jsonencode(var.blocked_countries)}"
        }
      }
      description = "Block specific countries"
    }
  }
}