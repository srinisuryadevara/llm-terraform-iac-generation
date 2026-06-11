provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "The ID of the project"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region for the VPC network"
}

variable "vpc_name" {
  type        = string
  default     = "example-vpc"
  description = "The name of the VPC network"
}

variable "subnet_cidr" {
  type        = string
  default     = "10.0.0.0/24"
  description = "The CIDR block for the subnet"
}

variable "subnet_name" {
  type        = string
  default     = "example-subnet"
  description = "The name of the subnet"
}

variable "firewall_rule_name" {
  type        = string
  default     = "example-firewall-rule"
  description = "The name of the firewall rule"
}

variable "cloud_router_name" {
  type        = string
  default     = "example-cloud-router"
  description = "The name of the Cloud Router"
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_compute_firewall" "firewall_rule" {
  name    = var.firewall_rule_name
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["example-target-tag"]
}

resource "google_compute_router" "cloud_router" {
  name    = var.cloud_router_name
  network = google_compute_network.vpc.id
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "example-nat"
  router                             = google_compute_router.cloud_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}