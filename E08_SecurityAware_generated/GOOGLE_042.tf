provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloudsql" {
  account_id = "cloudsql-sa"
  description = "Service account for Cloud SQL"
  tags = {
    environment = var.environment
  }
}

resource "google_project_iam_binding" "cloudsql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  members = [
    "serviceAccount:${google_service_account.cloudsql.email}",
  ]
}

resource "google_project_iam_binding" "cloudsql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  members = [
    "serviceAccount:${google_service_account.cloudsql.email}",
  ]
}

resource "google_compute_network" "private_network" {
  name                    = "private-network"
  auto_create_subnetworks = false
  tags = {
    environment = var.environment
  }
}

resource "google_compute_subnetwork" "private_subnetwork" {
  name          = "private-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.private_network.id
  region        = var.region
  tags = {
    environment = var.environment
  }
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.id
  tags = {
    environment = var.environment
  }
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "private_instance" {
  name                = "private-instance"
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false

  settings {
    tier              = "db-n1-standard-1"
    availability_type = "REGIONAL"
    disk_size         = 50
    disk_type         = "PD_SSD"
    disk_encryption   = "Google-managed key"
    activation_policy = "ALWAYS"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
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
        location         = var.region
      }
    }

    maintenance_window {
      day  = 7
      hour = 0
    }

    database_flags {
      name  = "cloudsql.enable_pgaudit"
      value = "on"
    }

    database_flags {
      name  = "cloudsql.enable_pg_cron"
      value = "on"
    }
  }

  tags = {
    environment = var.environment
  }
}

resource "google_sql_ssl_cert" "client_cert" {
  common_name = "client-cert"
  instance   = google_sql_database_instance.private_instance.name
}

resource "google_kms_key_ring" "key_ring" {
  name     = "key-ring"
  location = var.region
  tags = {
    environment = var.environment
  }
}

resource "google_kms_crypto_key" "crypto_key" {
  name     = "crypto-key"
  key_ring = google_kms_key_ring.key_ring.id
  tags = {
    environment = var.environment
  }
}

resource "google_kms_crypto_key_version" "crypto_key_version" {
  crypto_key = google_kms_crypto_key.crypto_key.id
}

resource "google_sql_database_instance" "private_instance_encryption" {
  name                = "private-instance-encryption"
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false

  settings {
    tier              = "db-n1-standard-1"
    availability_type = "REGIONAL"
    disk_size         = 50
    disk_type         = "PD_SSD"
    disk_encryption   = google_kms_crypto_key_version.crypto_key_version.id
    activation_policy = "ALWAYS"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
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
        location         = var.region
      }
    }

    maintenance_window {
      day  = 7
      hour = 0
    }

    database_flags {
      name  = "cloudsql.enable_pgaudit"
      value = "on"
    }

    database_flags {
      name  = "cloudsql.enable_pg_cron"
      value = "on"
    }
  }

  tags = {
    environment = var.environment
  }
}