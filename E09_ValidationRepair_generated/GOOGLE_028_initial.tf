provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_vpc" "private_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_subnetwork" "private_subnetwork" {
  name          = var.subnetwork_name
  ip_cidr_range = var.subnetwork_cidr
  network       = google_vpc.private_vpc.id
}

resource "google_memorystore_instance" "redis_instance" {
  name           = var.redis_instance_name
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_size

  redis_version = var.redis_version

  authorized_network = google_vpc.private_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_vpc.private_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_subnetwork.private_subnetwork.name]
}