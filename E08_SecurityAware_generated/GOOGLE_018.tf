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

variable "ssh_source_cidr" {
  type        = string
  description = "The source CIDR for SSH access"
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
  description = "The CIDR of the subnet"
}

variable "router_name" {
  type        = string
  description = "The name of the Cloud Router"
}

variable "bgp_asn" {
  type        = number
  description = "The BGP ASN for the Cloud Router"
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"

  tags = {
    environment = "production"
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  tags = {
    environment = "production"
  }
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh-rule"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_cidr]

  target_tags = ["ssh-access"]

  tags = {
    environment = "production"
  }
}

resource "google_compute_firewall" "icmp" {
  name    = "icmp-rule"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["icmp-access"]

  tags = {
    environment = "production"
  }
}

resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = google_compute_network.vpc.name

  bgp {
    asn = var.bgp_asn
  }

  tags = {
    environment = "production"
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-gateway"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  tags = {
    environment = "production"
  }
}