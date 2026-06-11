provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  type        = string
  default     = "example-vpc"
}

variable "subnet_name" {
  type        = string
  default     = "example-subnet"
}

variable "subnet_cidr" {
  type        = string
  default     = "10.0.0.0/24"
}

variable "firewall_name" {
  type        = string
  default     = "example-firewall"
}

variable "router_name" {
  type        = string
  default     = "example-router"
}

variable "asn" {
  type        = number
  default     = 64512
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  labels = {
    environment = "example"
    team        = "example-team"
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc.id
  region        = var.region
  labels = {
    environment = "example"
    team        = "example-team"
  }
}

resource "google_compute_firewall" "firewall" {
  name    = var.firewall_name
  network = google_compute_network.vpc.id
  labels = {
    environment = "example"
    team        = "example-team"
  }

  allow {
    protocol = "icmp"
    source_ranges = ["10.0.0.0/8"]
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
    source_ranges = ["10.0.0.0/8"]
  }
}

resource "google_compute_router" "router" {
  name    = var.router_name
  network = google_compute_network.vpc.id
  region  = var.region
  labels = {
    environment = "example"
    team        = "example-team"
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "example-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  labels = {
    environment = "example"
    team        = "example-team"
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