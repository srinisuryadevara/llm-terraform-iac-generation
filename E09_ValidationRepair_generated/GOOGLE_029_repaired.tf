provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [var.private_ip_range]
  labels = {
    environment = "production"
  }
}

resource "google_sql_database_instance" "private_ip_postgres" {
  name                = var.instance_name
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false
  labels = {
    environment = "production"
  }

  settings {
    tier              = var.tier
    availability_type = "REGIONAL"
    disk_size         = var.disk_size
    disk_type         = var.disk_type

    ip_configuration {
      ipv4_enabled = false
      private_network = var.vpc_id
    }

    backup_configuration {
      binary_log_enabled = true
      enabled            = true
      start_time         = var.backup_start_time
    }
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "private_ip_range" {
  type        = string
}

variable "instance_name" {
  type        = string
}

variable "tier" {
  type        = string
}

variable "disk_size" {
  type        = number
}

variable "disk_type" {
  type        = string
}

variable "backup_start_time" {
  type        = string
}

output "private_vpc_connection_id" {
  value = google_service_networking_connection.private_vpc_connection.id
}

output "private_ip_postgres_instance_id" {
  value = google_sql_database_instance.private_ip_postgres.id
}

output "private_ip_postgres_instance_connection_name" {
  value = google_sql_database_instance.private_ip_postgres.connection_name
}

output "private_ip_postgres_instance_private_ip_address" {
  value = google_sql_database_instance.private_ip_postgres.private_ip_address
}