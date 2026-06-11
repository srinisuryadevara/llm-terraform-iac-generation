#########################################################################################
# This configuration creates a Cloud SQL PostgreSQL instance in GCP with private IP and backup configuration
#
# Follow the directions here to set up a Terraform service account in GCP
# https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
#
# Happy Terraforming!
#########################################################################################

###########################
# VARIABLES
############################

# Google Cloud variables
variable "project_id" {}
variable "region" {
    default = "us-central1"
}
variable "database_version" {
    default = "POSTGRES_13"
}
variable "database_tier" {
    default = "db-g1-small"
}
variable "availability_type" {
    default = "REGIONAL"
}
variable "backup_start_time" {
    default = "00:00"
}

# Set this using the environment variable TF_VAR_database_password
variable "database_password" {}

variable "private_network_name" {}

############################
# PROVIDERS
############################

provider "google" {
  version = "~>4.0"
  project = var.project_id
  region  = var.region
}

############################
# RESOURCES
############################

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.private_network_name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.private_ip.name}/28"]
}

resource "google_compute_global_address" "private_ip" {
  name          = "cloud-sql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 28
}

resource "google_sql_database_instance" "postgre_instance" {
  name                = "postgre-instance"
  region              = var.region
  database_version   = var.database_version
  tier               = var.database_tier
  availability_type  = var.availability_type
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network_name
    }
    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                       = var.region
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }
  }

  initial_user {
    name     = "postgres"
    password = var.database_password
  }
}