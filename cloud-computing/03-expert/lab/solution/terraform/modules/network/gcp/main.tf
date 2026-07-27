variable "name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cidr" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

resource "google_compute_network" "this" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.name}-public"
  ip_cidr_range = cidrsubnet(var.cidr, 8, 0)
  region        = var.region
  network       = google_compute_network.this.id
  project       = var.project_id
}

resource "google_compute_subnetwork" "private" {
  name                     = "${var.name}-private"
  ip_cidr_range            = cidrsubnet(var.cidr, 8, 10)
  region                   = var.region
  network                  = google_compute_network.this.id
  project                  = var.project_id
  private_ip_google_access = true
}

resource "google_compute_router" "this" {
  name    = "${var.name}-router"
  region  = var.region
  network = google_compute_network.this.id
  project = var.project_id
}

resource "google_compute_router_nat" "this" {
  name                               = "${var.name}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

output "network_id" {
  value = google_compute_network.this.id
}

output "network_name" {
  value = google_compute_network.this.name
}

output "private_subnet_id" {
  value = google_compute_subnetwork.private.id
}

output "public_subnet_id" {
  value = google_compute_subnetwork.public.id
}
