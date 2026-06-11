provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.range_name]

  labels = {
    environment = "production"
    application = "database"
  }
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_id

  labels = {
    environment = "production"
    application = "database"
  }
}

resource "google_sql_database_instance" "postgres_instance" {
  name                = var.instance_name
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false

  labels = {
    environment = "production"
    application = "database"
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
      enabled                        = true
      start_time                     = "00:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
    }
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "tier" {
  type = string
}

variable "disk_size" {
  type = number
}

variable "disk_type" {
  type = string
}

output "sql_instance_name" {
  value       = google_sql_database_instance.postgres_instance.name
  description = "The name of the Cloud SQL instance"
}

output "sql_instance_id" {
  value       = google_sql_database_instance.postgres_instance.id
  description = "The ID of the Cloud SQL instance"
}

output "sql_instance_private_ip_address" {
  value       = google_compute_global_address.private_ip_address.address
  description = "The private IP address of the Cloud SQL instance"
}

output "sql_instance_connection_name" {
  value       = google_service_networking_connection.private_vpc_connection.name
  description = "The name of the private VPC connection"
}