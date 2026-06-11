provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "redis_network" {
  name                    = "redis-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "redis_subnetwork" {
  name          = "redis-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.redis_network.id
}

resource "google_redis_instance" "redis_instance" {
  name           = "redis-instance"
  tier           = "STANDARD_HA"
  memory_size_gb = 1

  redis_version = "6.x"

  authorized_network = google_compute_network.redis_network.id
}

resource "google_compute_firewall" "redis_firewall" {
  name    = "redis-firewall"
  network = google_compute_network.redis_network.id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = ["redis-instance"]
}

resource "google_compute_address" "redis_address" {
  name         = "redis-address"
  subnetwork   = google_compute_subnetwork.redis_subnetwork.id
  address_type = "INTERNAL"
}

output "redis_instance_name" {
  value = google_redis_instance.redis_instance.name
}

output "redis_instance_host" {
  value = google_compute_address.redis_address.address
}

output "redis_instance_port" {
  value = 6379
}