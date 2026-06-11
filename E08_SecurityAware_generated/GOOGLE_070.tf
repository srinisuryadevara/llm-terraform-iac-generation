provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "secure_bucket" {
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = var.kms_key_name
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    project     = var.project_id
  }
}

resource "google_kms_key_ring" "secure_key_ring" {
  name     = var.key_ring_name
  location = var.region
}

resource "google_kms_key" "secure_key" {
  name            = var.kms_key_name
  key_ring        = google_kms_key_ring.secure_key_ring.id
  rotation_period = "7776000s"
}

resource "google_kms_crypto_key_version" "secure_key_version" {
  crypto_key = google_kms_key.secure_key.id
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket"
}

variable "kms_key_name" {
  type        = string
  description = "The name of the KMS key"
}

variable "key_ring_name" {
  type        = string
  description = "The name of the KMS key ring"
}

variable "environment" {
  type        = string
  description = "The environment of the project"
}