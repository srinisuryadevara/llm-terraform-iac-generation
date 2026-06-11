provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "example" {
  provider = google
  location = var.location
  repository_id = var.repository_id
  format = var.format
  labels = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

resource "google_project_iam_binding" "example" {
  project = var.project_id
  role    = var.role
  members = [
    "serviceAccount:${var.service_account}",
  ]
  depends_on = [google_artifact_registry_repository.example]
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "location" {
  type = string
}

variable "repository_id" {
  type = string
}

variable "format" {
  type = string
}

variable "role" {
  type = string
}

variable "service_account" {
  type = string
}

output "artifact_registry_repository_id" {
  value = google_artifact_registry_repository.example.id
}

output "artifact_registry_repository_url" {
  value = google_artifact_registry_repository.example.repository_url
}

output "project_iam_binding_role" {
  value = google_project_iam_binding.example.role
}

output "project_iam_binding_members" {
  value = google_project_iam_binding.example.members
}