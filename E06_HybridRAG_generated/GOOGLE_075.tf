provider "google" {
  project = var.project_id
  region  = var.region
}

resource "random_id" "network_id" {
  byte_length = 8
}

resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 5.0"

  project_id   = var.project_id
  network_name = "my-custom-vpc-${random_id.network_id.hex}"

  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = var.subnet_1_name
      subnet_ip     = var.subnet_1_ip
      subnet_region = var.region_1
      subnet_private_access = "true"
    },
    {
      subnet_name   = var.subnet_2_name
      subnet_ip     = var.subnet_2_ip
      subnet_region = var.region_2
      subnet_private_access = "true"
    }
  ]

  secondary_ranges = {
    "${var.subnet_1_name}" = [
      {
        range_name    = "${var.subnet_1_name}-pod-cidr"
        ip_cidr_range = var.pod_1_cidr
      },
      {
        range_name    = "${var.subnet_1_name}-svc-cidr"
        ip_cidr_range = var.svc_1_cidr
      }
    ]
    "${var.subnet_2_name}" = [
      {
        range_name    = "${var.subnet_2_name}-pod-cidr"
        ip_cidr_range = var.pod_2_cidr
      },
      {
        range_name    = "${var.subnet_2_name}-svc-cidr"
        ip_cidr_range = var.svc_2_cidr
      }
    ]
  }
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = module.vpc.network_name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["http-server"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = module.vpc.network_name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = ["https-server"]
}

resource "google_compute_router" "router" {
  name    = "router"
  network = module.vpc.network_name
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