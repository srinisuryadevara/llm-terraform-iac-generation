variable "project_id" {
  type        = string
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "database_version" {
  type        = string
  description = "The version of the database to create"
  default     = "POSTGRES_11"
}

variable "database_tier" {
  type        = string
  description = "The tier of the database to create"
  default     = "db-f1-micro"
}

variable "backup_start_time" {
  type        = string
  description = "The start time for the backup configuration"
  default     = "00:00"
}

variable "backup_enabled" {
  type        = bool
  description = "Whether to enable backups for the database"
  default     = true
}

variable "private_network_name" {
  type        = string
  description = "The name of the private network to create"
}

variable "private_network_cidr" {
  type        = string
  description = "The CIDR range for the private network"
  default     = "10.0.0.0/16"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "private_network" {
  name                    = var.private_network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnetwork" {
  name          = "${var.private_network_name}-subnetwork"
  ip_cidr_range = var.private_network_cidr
  network       = google_compute_network.private_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_subnetwork.private_subnetwork.name]
}

resource "google_sql_database_instance" "private_ip_instance" {
  name                = "private-ip-instance"
  database_version   = var.database_version
  region              = var.region
  deletion_protection = false

  settings {
    tier              = var.database_tier
    availability_type = "REGIONAL"
    disk_size         = 50
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.private_network.id
    }

    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      binary_log_enabled             = true
      location                       = var.region
      point_in_time_recovery_enabled = true
    }
  }
}

resource "google_sql_database" "example_database" {
  name     = "example-database"
  instance = google_sql_database_instance.private_ip_instance.name
}