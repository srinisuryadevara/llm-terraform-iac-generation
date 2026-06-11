provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_ip" {
  type = string
}

variable "firewall_name" {
  type = string
}

variable "router_name" {
  type = string
}

variable "router_asn" {
  type = number
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  labels = {
    environment = "dev"
    project     = var.project_id
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_ip
  network       = google_compute_network.vpc.id
  region        = var.region
  labels = {
    environment = "dev"
    project     = var.project_id
  }
}

resource "google_compute_firewall" "firewall" {
  name    = var.firewall_name
  network = google_compute_network.vpc.id
  labels = {
    environment = "dev"
    project     = var.project_id
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

  allow {
    protocol = "icmp"
    source_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  source_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

resource "google_compute_router" "router" {
  name    = var.router_name
  network = google_compute_network.vpc.id
  region  = var.region
  labels = {
    environment = "dev"
    project     = var.project_id
  }
  bgp {
    asn = var.router_asn
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.router_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  labels = {
    environment = "dev"
    project     = var.project_id
  }
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_id" {
  value = google_compute_subnetwork.subnet.id
}

output "firewall_id" {
  value = google_compute_firewall.firewall.id
}

output "router_id" {
  value = google_compute_router.router.id
}

output "nat_id" {
  value = google_compute_router_nat.nat.id
}