variable "project" {
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

variable "database_name" {
  type        = string
  description = "The name of the database to create"
}

variable "database_username" {
  type        = string
  description = "The username for the database"
}

variable "database_password" {
  type        = string
  description = "The password for the database"
  sensitive   = true
}

variable "backup_start_time" {
  type        = string
  description = "The start time for the backup in 24 hour format in the UTC timezone"
  default     = "02:00"
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
  project = var.project
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
  region        = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_subnetwork.private_subnetwork.name]
}

resource "google_sql_database_instance" "private_instance" {
  name                = "private-sql-instance"
  database_version   = var.database_version
  region              = var.region
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
    }
    backup_configuration {
      enabled            = var.backup_enabled
      start_time         = var.backup_start_time
      binary_log_enabled = true
    }
  }
}

resource "google_sql_database" "private_database" {
  name     = var.database_name
  instance = google_sql_database_instance.private_instance.name
}

resource "google_sql_user" "private_user" {
  name     = var.database_username
  instance = google_sql_database_instance.private_instance.name
  host     = "%"
  password = var.database_password
}