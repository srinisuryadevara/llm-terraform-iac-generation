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

resource "google_sql_database_instance" "private_ip_instance" {
  name                = "private-ip-instance"
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
      ipv4_enabled    = false
      private_network = var.vpc_id
    }
    maintenance_window {
      day          = 7
      hour         = 0
      update_track = "stable"
    }
    database_flags {
      name  = "log_connections"
      value = "on"
    }
    database_flags {
      name  = "log_disconnections"
      value = "on"
    }
    backup_configuration {
      enabled                        = true
      start_time                     = "00:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      retained_backups               = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit  = "COUNT"
      }
    }
  }
}

resource "google_sql_user" "users" {
  name     = "postgres"
  instance = google_sql_database_instance.private_ip_instance.name
  host     = "%"
  password = random_password.password.result
}