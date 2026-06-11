provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_sql_database_instance" "private_ip" {
  provider = google

  database_version = "POSTGRES_14"
  name             = var.instance_name
  region           = var.region
  project          = var.project_id

  settings {
    tier              = var.tier
    availability_type = "REGIONAL"
    disk_size         = var.disk_size
    disk_type         = var.disk_type

    ip_configuration {
      ipv4_enabled = false
      private_network = var.vpc_network
    }

    backup_configuration {
      binary_log_enabled = true
      enabled             = true
      start_time          = var.backup_start_time
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "-1"
    }
  }
}

resource "google_service_account" "sql_sa" {
  provider = google

  account_id = var.service_account_id
  project    = var.project_id
}

resource "google_project_iam_binding" "sql_sa_role" {
  provider = google

  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  members = [google_service_account.sql_sa.email]
}

resource "google_kms_key_ring" "sql_key_ring" {
  provider = google

  name     = var.key_ring_name
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "sql_key" {
  provider = google

  name     = var.crypto_key_name
  key_ring = google_kms_key_ring.sql_key_ring.id
  project  = var.project_id
}

resource "google_kms_key_ring_iam_binding" "sql_key_ring_iam" {
  provider = google

  key_ring_id = google_kms_key_ring.sql_key_ring.id
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members     = [google_service_account.sql_sa.email]
}

resource "google_sql_database_instance" "sql_instance_with_kms" {
  provider = google

  database_version = "POSTGRES_14"
  name             = var.instance_name_with_kms
  region           = var.region
  project          = var.project_id

  settings {
    tier              = var.tier
    availability_type = "REGIONAL"
    disk_size         = var.disk_size
    disk_type         = var.disk_type

    ip_configuration {
      ipv4_enabled = false
      private_network = var.vpc_network
    }

    backup_configuration {
      binary_log_enabled = true
      enabled             = true
      start_time          = var.backup_start_time
      encryption_key_name = google_kms_crypto_key.sql_key.id
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "-1"
    }
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "instance_name_with_kms" {
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

variable "vpc_network" {
  type = string
}

variable "backup_start_time" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "key_ring_name" {
  type = string
}

variable "crypto_key_name" {
  type = string
}

variable "tags" {
  type = list(string)
}