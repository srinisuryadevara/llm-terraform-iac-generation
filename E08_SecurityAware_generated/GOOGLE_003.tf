provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "secure_bucket" {
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  encryption {
    default_kms_key_name = var.kms_key_name
  }
  labels = {
    environment = var.environment
    owner       = var.owner
  }
}

resource "google_kms_key_ring" "secure_key_ring" {
  name     = var.key_ring_name
  location = var.region
  labels = {
    environment = var.environment
    owner       = var.owner
  }
}

resource "google_kms_crypto_key" "secure_crypto_key" {
  name     = var.crypto_key_name
  key_ring = google_kms_key_ring.secure_key_ring.id
  labels = {
    environment = var.environment
    owner       = var.owner
  }
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

variable "crypto_key_name" {
  type        = string
  description = "GCP KMS Crypto Key Name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. dev, prod)"
}

variable "owner" {
  type        = string
  description = "Owner/Team Name"
}