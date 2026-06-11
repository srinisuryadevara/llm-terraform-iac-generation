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
  description = "The region to create the resources in"
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

variable "http_source_cidr" {
  type        = string
  description = "The source CIDR range for HTTP access"
}

variable "https_source_cidr" {
  type        = string
  description = "The source CIDR range for HTTPS access"
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
  network       = google_compute_network.vpc.id
  region        = var.region

  tags = {
    environment = "production"
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
    environment = "production"
  }
}

resource "google_compute_firewall" "http" {
  name    = "allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [var.http_source_cidr]

  target_tags = ["http-access"]

  tags = {
    environment = "production"
  }
}

resource "google_compute_firewall" "https" {
  name    = "allow-https"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [var.https_source_cidr]

  target_tags = ["https-access"]

  tags = {
    environment = "production"
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
    environment = "production"
  }
}