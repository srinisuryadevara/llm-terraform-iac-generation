provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
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

variable "role" {
  type = string
}

variable "members" {
  type = list(string)
}

resource "google_artifact_registry_repository" "example" {
  provider = google
  location  = var.region
  repository_id = var.repository_id
  format       = "DOCKER"
}

resource "google_artifact_registry_repository_iam_binding" "example" {
  provider = google
  location  = google_artifact_registry_repository.example.location
  repository = google_artifact_registry_repository.example.name
  role        = var.role
  members     = var.members
}