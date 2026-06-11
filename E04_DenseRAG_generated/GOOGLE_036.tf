terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

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

variable "subnet_1_name" {
  type = string
}

variable "subnet_1_ip" {
  type = string
}

variable "subnet_1_region" {
  type = string
}

variable "subnet_2_name" {
  type = string
}

variable "subnet_2_ip" {
  type = string
}

variable "subnet_2_region" {
  type = string
}

variable "pod_1_cidr" {
  type = string
}

variable "svc_1_cidr" {
  type = string
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_1" {
  name          = var.subnet_1_name
  ip_cidr_range = var.subnet_1_ip
  region        = var.subnet_1_region
  network       = google_compute_network.vpc.self_link
}

resource "google_compute_subnetwork" "subnet_2" {
  name          = var.subnet_2_name
  ip_cidr_range = var.subnet_2_ip
  region        = var.subnet_2_region
  network       = google_compute_network.vpc.self_link
}

resource "google_compute_subnetwork" "subnet_1_secondary" {
  name          = "${var.subnet_1_name}-secondary"
  ip_cidr_range = var.pod_1_cidr
  region        = var.subnet_1_region
  network       = google_compute_network.vpc.self_link
  purpose       = "PRIVATE"
}

resource "google_compute_subnetwork" "subnet_1_secondary_svc" {
  name          = "${var.subnet_1_name}-secondary-svc"
  ip_cidr_range = var.svc_1_cidr
  region        = var.subnet_1_region
  network       = google_compute_network.vpc.self_link
  purpose       = "PRIVATE"
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_router" "router" {
  name    = "router"
  network = google_compute_network.vpc.self_link
  bgp {
    asn            = 64514
    advertise_mode = "CUSTOM"
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}