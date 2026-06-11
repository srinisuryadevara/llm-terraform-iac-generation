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

  labels = {
    environment = var.environment
    project     = var.project_id
  }
}

resource "google_kms_key_ring" "secure_key_ring" {
  name     = var.key_ring_name
  location = var.region
}

resource "google_kms_crypto_key" "secure_crypto_key" {
  name     = var.kms_key_name
  key_ring = google_kms_key_ring.secure_key_ring.id
}

resource "google_kms_crypto_key_version" "secure_crypto_key_version" {
  crypto_key = google_kms_crypto_key.secure_crypto_key.id
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "bucket_name" {
  type        = string
  description = "GCP Cloud Storage Bucket Name"
}

variable "kms_key_name" {
  type        = string
  description = "GCP KMS Key Name"
}

variable "key_ring_name" {
  type        = string
  description = "GCP KMS Key Ring Name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. dev, prod)"
}