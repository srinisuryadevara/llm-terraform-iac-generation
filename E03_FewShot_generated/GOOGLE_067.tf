provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "example" {
  provider = google

  location = var.region
  repository_id = var.repository_id
  format = var.repository_format
}

resource "google_artifact_registry_repository_iam_binding" "example" {
  provider = google

  location = google_artifact_registry_repository.example.location
  repository = google_artifact_registry_repository.example.name
  role       = var.repository_iam_role
  members   = var.repository_iam_members
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
}

variable "repository_id" {
  type        = string
}

variable "repository_format" {
  type        = string
}

variable "repository_iam_role" {
  type        = string
}

variable "repository_iam_members" {
  type        = list(string)
}