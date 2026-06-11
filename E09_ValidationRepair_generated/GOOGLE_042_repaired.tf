provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [var.peering_range_name]
  labels = {
    environment = "production"
    application = "database"
  }
}

resource "google_sql_database_instance" "private_ip_postgres" {
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
      start_time                     = var.backup_start_time
      location                       = var.backup_location
      point_in_time_recovery_enabled = true
    }
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "peering_range_name" {
  type        = string
  sensitive   = true
}

variable "instance_name" {
  type        = string
  sensitive   = true
}

variable "tier" {
  type        = string
  sensitive   = true
}

variable "disk_size" {
  type        = number
  sensitive   = true
}

variable "disk_type" {
  type        = string
  sensitive   = true
}

variable "backup_start_time" {
  type        = string
  sensitive   = true
}

variable "backup_location" {
  type        = string
  sensitive   = true
}

output "private_ip_postgres_instance_name" {
  value       = google_sql_database_instance.private_ip_postgres.name
  description = "The name of the Cloud SQL instance"
}

output "private_ip_postgres_instance_id" {
  value       = google_sql_database_instance.private_ip_postgres.id
  description = "The ID of the Cloud SQL instance"
}

output "private_ip_postgres_private_ip_address" {
  value       = google_sql_database_instance.private_ip_postgres.private_ip_address
  description = "The private IP address of the Cloud SQL instance"
}

output "private_vpc_connection_id" {
  value       = google_service_networking_connection.private_vpc_connection.id
  description = "The ID of the private VPC connection"
}