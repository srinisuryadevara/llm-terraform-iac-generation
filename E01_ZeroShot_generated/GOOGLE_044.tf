provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_id
}

resource "random_password" "password" {
  length = 16
  special = true
}

resource "google_sql_database_instance" "private_ip_postgres" {
  name                = "private-ip-postgres"
  region               = var.region
  database_version     = "POSTGRES_14"
  deletion_protection  = false

  settings {
    tier                        = "db-g1-small"
    availability_type          = "REGIONAL"
    disk_autoresize            = true
    disk_autoresize_limit      = 0
    disk_size                  = 50
    disk_type                  = "PD_SSD"
    ip_configuration {
      ipv4_enabled = false
      private_network = var.vpc_id
    }
    maintenance_window {
      day  = 7
      hour = 0
    }
    backup_configuration {
      binary_log_enabled = true
      enabled            = true
      start_time         = "00:00"
    }
  }
}

resource "google_sql_user" "users" {
  name     = "postgres"
  instance = google_sql_database_instance.private_ip_postgres.name
  host     = "%"
  password = random_password.password.result
}