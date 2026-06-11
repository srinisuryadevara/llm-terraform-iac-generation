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
}

resource "google_kms_crypto_key" "example" {
  provider = google

  name            = var.kms_crypto_key_name
  key_ring        = google_kms_key_ring.example.id
  rotation_period = "604800s"
}

resource "google_kms_key_ring_iam_binding" "example" {
  provider = google

  key_ring_id = google_kms_key_ring.example.id
  role        = "roles/owner"
  members     = var.kms_members
}

resource "google_artifact_registry_repository_iam_policy" "example" {
  provider = google

  repository   = google_artifact_registry_repository.example.repository_id
  location     = google_artifact_registry_repository.example.location
  policy_data = data.google_iam_policy.example.policy_data
}

data "google_iam_policy" "example" {
  binding {
    role = "roles/artifactregistry.reader"
    members = var.members
  }
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the repository"
}

variable "repository_id" {
  type        = string
  description = "The ID of the repository"
}

variable "environment" {
  type        = string
  description = "The environment of the repository"
}

variable "team" {
  type        = string
  description = "The team of the repository"
}

variable "members" {
  type        = list(string)
  description = "The members of the repository"
}

variable "kms_key_ring_name" {
  type        = string
  description = "The name of the KMS key ring"
}

variable "kms_crypto_key_name" {
  type        = string
  description = "The name of the KMS crypto key"
}

variable "kms_members" {
  type        = list(string)
  description = "The members of the KMS key ring"
}