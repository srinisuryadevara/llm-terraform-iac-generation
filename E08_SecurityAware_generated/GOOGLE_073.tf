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
  description = "The region to deploy to"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The source CIDR for SSH access"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

variable "subnet_cidr" {
  type        = string
  description = "The CIDR of the subnet"
}

variable "cloud_router_name" {
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
  name    = "ssh-firewall"
  network = google_compute_network.vpc.id

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
  name    = "icmp-firewall"
  network = google_compute_network.vpc.id

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.ssh_source_cidr]

  target_tags = ["icmp-access"]

  tags = {
    environment = "production"
  }
}

resource "google_compute_firewall" "https" {
  name    = "https-firewall"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["https-access"]

  tags = {
    environment = "production"
  }
}

resource "google_compute_router" "router" {
  name    = var.cloud_router_name
  region  = var.region
  network = google_compute_network.vpc.id

  bgp {
    asn = var.bgp_asn
  }

  tags = {
    environment = "production"
  }
}