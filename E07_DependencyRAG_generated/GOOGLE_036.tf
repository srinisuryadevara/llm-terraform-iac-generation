terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.68.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  credentials = file(var.credentials_file)
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_1" {
  name          = var.subnet_1_name
  region        = var.region_1
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.subnet_1_ip
}

resource "google_compute_subnetwork" "subnet_2" {
  name          = var.subnet_2_name
  region        = var.region_2
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.subnet_2_ip
}

resource "google_compute_firewall" "allow_http" {
  name    = var.firewall_name
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.firewall_name}-ssh"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_router" "router" {
  name    = var.router_name
  network = google_compute_network.vpc.self_link
  bgp {
    asn            = 64514
    advertise_mode = "CUSTOM"
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}