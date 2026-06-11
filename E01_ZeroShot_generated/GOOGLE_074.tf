provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "example" {
  provider = google
  location  = var.region
  repository_id = var.repository_id
  format        = var.format
}

resource "google_artifact_registry_repository_iam_binding" "example" {
  provider   = google
  location   = google_artifact_registry_repository.example.location
  repository = google_artifact_registry_repository.example.repository_id
  role       = var.role
  members    = var.members
}

variable "project_id" {
  type = string
}

variable "region" {
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

variable "members" {
  type = list(string)
}