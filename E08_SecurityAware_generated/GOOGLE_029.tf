provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "database_name" {
  type        = string
  description = "PostgreSQL Database Name"
}

variable "database_username" {
  type        = string
  description = "PostgreSQL Database Username"
}

variable "database_password" {
  type        = string
  sensitive   = true
  description = "PostgreSQL Database Password"
}

variable "private_network_name" {
  type        = string
  description = "Private Network Name"
}

variable "private_network_cidr" {
  type        = string
  description = "Private Network CIDR"
}

variable "backup_start_time" {
  type        = string
  description = "Backup Start Time (HH:MM)"
}

resource "google_sql_database_instance" "private_ip_postgres" {
  name                = "private-ip-postgres"
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false

  settings {
    tier              = "db-g1-small"
    availability_type = "REGIONAL"
    disk_size         = 50
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.private_network.id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                       = var.region
      point_in_time_recovery_enabled = true
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }
}

resource "google_compute_network" "private_network" {
  name                    = var.private_network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnetwork" {
  name          = "private-subnetwork"
  ip_cidr_range = var.private_network_cidr
  network       = google_compute_network.private_network.id
  region        = var.region
}

resource "google_sql_user" "users" {
  name     = var.database_username
  instance = google_sql_database_instance.private_ip_postgres.name
  host     = "%"
  password = var.database_password
}

resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.private_ip_postgres.name
}

resource "google_kms_key_ring" "key_ring" {
  name     = "key-ring"
  location = var.region
}

resource "google_kms_crypto_key" "crypto_key" {
  name     = "crypto-key"
  key_ring = google_kms_key_ring.key_ring.id
}

resource "google_kms_key_ring_iam_policy" "key_ring_policy" {
  key_ring_id = google_kms_key_ring.key_ring.id
  policy      = data.google_iam_policy.key_ring_policy.policy
}

data "google_iam_policy" "key_ring_policy" {
  binding {
    role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    members = [
      "serviceAccount:service-${var.project_id}@gcp-sa-cloud-sql.iam.gserviceaccount.com",
    ]
  }
}

resource "google_sql_database_instance" "encryption" {
  name                = google_sql_database_instance.private_ip_postgres.name
  database_version   = google_sql_database_instance.private_ip_postgres.database_version
  region              = var.region

  settings {
    disk_encryption_configuration {
      kms_key_name = google_kms_crypto_key.crypto_key.id
    }
  }
}