provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to create resources in"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC network"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

variable "subnet_cidr" {
  type        = string
  description = "The CIDR range of the subnet"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The source CIDR range for SSH access"
}

variable "environment" {
  type        = string
  description = "The environment to create resources in"
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"

  tags = {
    environment = var.environment
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc.id
  region        = var.region

  tags = {
    environment = var.environment
  }
}

resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_cidr]

  target_tags = ["ssh-access"]

  tags = {
    environment = var.environment
  }
}

resource "google_compute_firewall" "icmp" {
  name    = "allow-icmp"
  network = google_compute_network.vpc.id

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.ssh_source_cidr]

  target_tags = ["icmp-access"]

  tags = {
    environment = var.environment
  }
}

resource "google_compute_router" "router" {
  name    = "router"
  network = google_compute_network.vpc.id
  region  = var.region

  bgp {
    asn = 64514
  }

  tags = {
    environment = var.environment
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  tags = {
    environment = var.environment
  }
}