provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}

variable "repository_id" {
  type        = string
  description = "The ID of the Artifact Registry repository"
}

variable "location" {
  type        = string
  description = "The location of the Artifact Registry repository"
}

variable "role" {
  type        = string
  description = "The role to bind to the Artifact Registry repository"
}

variable "members" {
  type        = list(string)
  description = "The members to bind to the Artifact Registry repository"
}

resource "google_artifact_registry_repository" "example" {
  provider = google
  location = var.location
  repository_id = var.repository_id
  format = "DOCKER"
}

resource "google_artifact_registry_repository_iam_binding" "example" {
  provider = google
  location = google_artifact_registry_repository.example.location
  repository = google_artifact_registry_repository.example.name
  role       = var.role
  members   = var.members
}