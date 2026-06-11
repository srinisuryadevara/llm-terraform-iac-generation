provider "google" {
  project     = var.project_id
  region      = var.region
}

resource "random_id" "network_id" {
  byte_length = 8
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 2.5.0"

  project_id   = var.project_id
  network_name = "my-vpc-${random_id.network_id.hex}"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "subnet-01"
      subnet_ip             = "10.10.10.0/24"
      subnet_region         = var.region
    },
    {
      subnet_name           = "subnet-02"
      subnet_ip             = "10.10.20.0/24"
      subnet_region         = var.region
    }
  ]
}

resource "google_compute_firewall" "ingress-rules" {
  project     = var.project_id
  name        = "tf-firewall"
  network     = module.vpc.network_name
  description = "Creates firewall rule targeting tagged instances"

  direction   = "INGRESS"

  allow {
    protocol  = "tcp"
    ports     = ["80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "egress-rules" {
  project     = var.project_id
  name        = "tf-egress-firewall"
  network     = module.vpc.network_name
  description = "Creates firewall rule targeting tagged instances"

  direction   = "EGRESS"

  allow {
    protocol  = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

resource "google_compute_router" "router" {
  project = var.project_id
  region  = var.region
  name    = "my-router"
  network = module.vpc.network_name
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}