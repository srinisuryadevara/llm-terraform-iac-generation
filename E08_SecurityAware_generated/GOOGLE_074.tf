provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "example" {
  provider = google

  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"

  labels = {
    environment = var.environment
    team        = var.team
  }
}

resource "google_artifact_registry_repository_iam_binding" "example" {
  provider = google

  location      = google_artifact_registry_repository.example.location
  repository   = google_artifact_registry_repository.example.repository_id
  role         = "roles/artifactregistry.reader"
  members      = var.members

  depends_on = [google_artifact_registry_repository.example]
}

resource "google_kms_key_ring" "example" {
  provider = google

  name     = var.kms_key_ring_name
  location = var.region

  labels = {
    environment = var.environment
    team        = var.team
  }
}

resource "google_kms_crypto_key" "example" {
  provider = google

  name     = var.kms_crypto_key_name
  key_ring = google_kms_key_ring.example.id

  labels = {
    environment = var.environment
    team        = var.team
  }
}

resource "google_kms_crypto_key_version" "example" {
  provider = google

  crypto_key = google_kms_crypto_key.example.id

  labels = {
    environment = var.environment
    team        = var.team
  }
}

resource "google_storage_bucket" "example" {
  provider = google

  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = google_kms_crypto_key.example.id
  }

  labels = {
    environment = var.environment
    team        = var.team
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "repository_id" {
  type        = string
  description = "Artifact Registry Repository ID"
}

variable "members" {
  type        = list(string)
  description = "List of members to bind to the IAM role"
}

variable "kms_key_ring_name" {
  type        = string
  description = "KMS Key Ring Name"
}

variable "kms_crypto_key_name" {
  type        = string
  description = "KMS Crypto Key Name"
}

variable "bucket_name" {
  type        = string
  description = "Storage Bucket Name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "team" {
  type        = string
  description = "Team"
}