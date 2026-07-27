resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.project_name}-public"
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, 0)
  region        = var.region
  network       = google_compute_network.main.id
}

resource "google_compute_subnetwork" "private" {
  name                     = "${var.project_name}-private"
  ip_cidr_range            = cidrsubnet(var.vpc_cidr, 8, 10)
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "data" {
  name                     = "${var.project_name}-data"
  ip_cidr_range            = cidrsubnet(var.vpc_cidr, 8, 20)
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  name    = "${var.project_name}-router"
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
}

resource "google_compute_firewall" "allow_lb_to_app" {
  name    = "${var.project_name}-allow-lb-health"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  # Google LB health check ranges
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["cloud-run-direct-vpc"] # ใช้เมื่อผูก Direct VPC; Cloud Run managed อาจไม่ต้อง
}
