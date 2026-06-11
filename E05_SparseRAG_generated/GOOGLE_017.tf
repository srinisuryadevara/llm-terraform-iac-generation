variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "location" {
  type        = string
  description = "The location of the repository"
}

variable "repository_id" {
  type        = string
  description = "The ID of the repository"
}

variable "role" {
  type        = string
  description = "The role to bind to the repository"
}

variable "members" {
  type        = list(string)
  description = "The members to bind to the repository"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_artifact_registry_repository" "default" {
  project       = var.project_id
  location      = var.location
  repository_id = var.repository_id
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_binding" "default" {
  project       = var.project_id
  location      = var.location
  repository    = google_artifact_registry_repository.default.repository_id
  role          = var.role
  members       = var.members
}