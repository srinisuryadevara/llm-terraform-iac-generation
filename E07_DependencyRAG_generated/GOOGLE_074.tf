provider "google" {
  version = "~> 4.0"
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
  description = "The IAM role to bind to the repository"
}

variable "members" {
  type        = list(string)
  description = "The members to bind to the repository"
}

resource "google_artifact_registry_repository" "example" {
  provider = google
  location = var.location
  repository_id = var.repository_id
  format = "DOCKER"
}

resource "google_project_iam_binding" "example" {
  provider = google
  project  = var.project_id
  role     = var.role
  members  = var.members
}

resource "google_project_iam_member" "example" {
  provider = google
  project  = var.project_id
  role     = var.role
  member   = "serviceAccount:${google_service_account.example.email}"
}

resource "google_service_account" "example" {
  provider = google
  account_id = "artifact-registry-sa"
}

resource "google_artifact_registry_repository_iam_binding" "example" {
  provider = google
  location = google_artifact_registry_repository.example.location
  repository = google_artifact_registry_repository.example.name
  role     = var.role
  members  = var.members
}