provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "example" {
  provider = google

  location      = var.location
  repository_id = var.repository_id
  format        = var.format

  labels = {
    environment = "example"
    managed-by  = "terraform"
  }
}

resource "google_artifact_registry_repository_iam_binding" "example" {
  provider = google

  location      = google_artifact_registry_repository.example.location
  repository   = google_artifact_registry_repository.example.repository_id
  role         = var.role
  members      = var.members
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
}

variable "location" {
  type        = string
}

variable "repository_id" {
  type        = string
}

variable "format" {
  type        = string
}

variable "role" {
  type        = string
}

variable "members" {
  type        = list(string)
}

output "repository_id" {
  value       = google_artifact_registry_repository.example.repository_id
  description = "The ID of the Artifact Registry repository"
}

output "repository_url" {
  value       = google_artifact_registry_repository.example.id
  description = "The URL of the Artifact Registry repository"
}

output "iam_binding_role" {
  value       = google_artifact_registry_repository_iam_binding.example.role
  description = "The role of the IAM binding"
}

output "iam_binding_members" {
  value       = google_artifact_registry_repository_iam_binding.example.members
  description = "The members of the IAM binding"
}