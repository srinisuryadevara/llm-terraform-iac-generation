provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "private_network" {
  name                    = "private-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnetwork" {
  name          = "private-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.private_network.id
  region        = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_subnetwork.private_subnetwork.name]
}

resource "random_password" "password" {
  length = 16
  special = true
}

resource "google_sql_database_instance" "private_ip_instance" {
  name                = "private-ip-instance"
  region               = var.region
  database_version     = "POSTGRES_14"
  deletion_protection  = false

  settings {
    tier              = "db-g1-small"
    disk_size          = 50
    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "08:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
    }
  }
}

resource "google_sql_database" "database" {
  name     = "mydatabase"
  instance = google_sql_database_instance.private_ip_instance.name
}

resource "google_sql_user" "users" {
  name     = "myuser"
  instance = google_sql_database_instance.private_ip_instance.name
  host     = "%"
  password = random_password.password.result
}