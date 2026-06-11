# Configure the Google Cloud Provider
provider "google" {
  project = var.project
  region  = var.region
}

# Create a VPC network
resource "google_compute_network" "main" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# Create subnets
resource "google_compute_subnetwork" "subnet_1" {
  name          = var.subnet_1_name
  ip_cidr_range = var.subnet_1_ip
  region        = var.region_1
  network       = google_compute_network.main.id
}

resource "google_compute_subnetwork" "subnet_2" {
  name          = var.subnet_2_name
  ip_cidr_range = var.subnet_2_ip
  region        = var.region_2
  network       = google_compute_network.main.id
}

# Create firewall rules
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create Cloud Router
resource "google_compute_router" "router" {
  name    = var.router_name
  network = google_compute_network.main.id
  bgp {
    asn            = var.router_asn
    advertise_mode = "CUSTOM"
  }
}

# Create NAT Gateway
resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}