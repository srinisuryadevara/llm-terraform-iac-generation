terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "=3.68.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  credentials = file(var.credentials_file)
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "5.0"

  project_id   = var.project
  network_name = var.vpc_name
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "${var.subnet_1_name}"
      subnet_ip     = "${var.subnet_1_ip}"
      subnet_region = "${var.region}"
      subnet_private_access = "true"
    },
    {
      subnet_name   = "${var.subnet_2_name}"
      subnet_ip     = "${var.subnet_2_ip}"
      subnet_region = "${var.region}"
      subnet_private_access = "true"
    }
  ]

  secondary_ranges = {
    "${var.subnet_1_name}" = [
      {
        range_name    = "${var.subnet_1_name}-pod-cidr"
        ip_cidr_range = "${var.pod_1_cidr}"
      },
      {
        range_name    = "${var.subnet_1_name}-svc-cidr"
        ip_cidr_range = "${var.svc_1_cidr}"
      }
    ]
    "${var.subnet_2_name}" = [
      {
        range_name    = "${var.subnet_2_name}-pod-cidr"
        ip_cidr_range = "${var.pod_2_cidr}"
      },
      {
        range_name    = "${var.subnet_2_name}-svc-cidr"
        ip_cidr_range = "${var.svc_2_cidr}"
      }
    ]
  }
}

resource "google_compute_firewall" "http-server" {
  name    = "${var.vpc_name}-default-allow-ssh-http"
  network = module.vpc.network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  network = module.vpc.network.self_link
  bgp {
    asn            = 64514
    advertise_mode = "CUSTOM"
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}