variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "bucket_name" {
  type        = string
  description = "Name of the Cloud Storage bucket"
}

variable "storage_class" {
  type        = string
  description = "Storage class of the Cloud Storage bucket"
}

variable "lifecycle_rule_age" {
  type        = number
  description = "Age in days for the lifecycle rule"
}

variable "lifecycle_rule_prefix" {
  type        = string
  description = "Prefix for the lifecycle rule"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_storage_bucket" "example" {
  name                        = var.bucket_name
  storage_class              = var.storage_class
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = var.lifecycle_rule_age
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      matches_prefix = var.lifecycle_rule_prefix
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_key_name = google_kms_crypto_key.example.id
      }
    }
  }

  labels = {
    environment = "example"
  }
}

resource "google_kms_key_ring" "example" {
  name     = "example-keyring"
  location = var.region
  project  = var.project
}

resource "google_kms_crypto_key" "example" {
  name            = "example-key"
  key_ring        = google_kms_key_ring.example.id
  purpose         = "ENCRYPTION"
  rotation_period = "7776000s"
}