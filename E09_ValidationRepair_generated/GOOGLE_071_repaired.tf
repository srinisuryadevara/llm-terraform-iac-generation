# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a private VPC connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [var.private_ip_range]

  # Add labels for identification and cost management
  labels = {
    environment = "production"
    application = "database"
  }
}

# Create a Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "postgre_sql_instance" {
  name                = var.instance_name
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false

  # Add labels for identification and cost management
  labels = {
    environment = "production"
    application = "database"
  }

  settings {
    tier              = var.instance_tier
    availability_type = "REGIONAL"
    disk_size         = var.disk_size
    disk_type         = var.disk_type

    ip_configuration {
      ipv4_enabled = false
      private_network = var.vpc_id
    }

    backup_configuration {
      enabled                        = true
      binary_log_enabled             = true
      point_in_time_recovery_enabled = true
      start_time                     = var.backup_start_time
      location                       = var.region
    }
  }
}

# Declare input variables
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

variable "instance_tier" {
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

# Declare output values for key resource attributes
output "private_vpc_connection_id" {
  value       = google_service_networking_connection.private_vpc_connection.id
  description = "The ID of the private VPC connection"
}

output "postgre_sql_instance_id" {
  value       = google_sql_database_instance.postgre_sql_instance.id
  description = "The ID of the Cloud SQL PostgreSQL instance"
}

output "postgre_sql_instance_connection_name" {
  value       = google_sql_database_instance.postgre_sql_instance.connection_name
  description = "The connection name of the Cloud SQL PostgreSQL instance"
}

output "postgre_sql_instance_private_ip_address" {
  value       = google_sql_database_instance.postgre_sql_instance.private_ip_address
  description = "The private IP address of the Cloud SQL PostgreSQL instance"
}