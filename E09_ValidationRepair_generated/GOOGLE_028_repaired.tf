provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_vpc" "private_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  labels = {
    environment = "production"
    project     = var.project_id
  }
}

resource "google_subnetwork" "private_subnetwork" {
  name          = var.subnetwork_name
  ip_cidr_range = var.subnetwork_cidr
  network       = google_vpc.private_vpc.id
  labels = {
    environment = "production"
    project     = var.project_id
  }
}

resource "google_memorystore_instance" "redis_instance" {
  name           = var.redis_instance_name
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_size

  redis_version = var.redis_version

  authorized_network = google_vpc.private_vpc.id
  labels = {
    environment = "production"
    project     = var.project_id
  }
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_vpc.private_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_subnetwork.private_subnetwork.name]
  labels = {
    environment = "production"
    project     = var.project_id
  }
}

output "vpc_id" {
  value       = google_vpc.private_vpc.id
  description = "The ID of the private VPC"
}

output "subnetwork_id" {
  value       = google_subnetwork.private_subnetwork.id
  description = "The ID of the private subnetwork"
}

output "redis_instance_id" {
  value       = google_memorystore_instance.redis_instance.name
  description = "The name of the Memorystore Redis instance"
}

output "redis_instance_host" {
  value       = google_memorystore_instance.redis_instance.host
  description = "The hostname of the Memorystore Redis instance"
}

output "redis_instance_port" {
  value       = google_memorystore_instance.redis_instance.port
  description = "The port of the Memorystore Redis instance"
}