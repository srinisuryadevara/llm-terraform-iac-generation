terraform {
  required_providers {
    google = {
      version = ">= 3.45.0"
    }
  }
}

variable "project_id" {}
variable "location" {
  default = "us-central1"
}
variable "repository_id" {}
variable "role" {}
variable "member" {}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_artifact_registry_repository" "example" {
  provider = google
  location  = var.location
  repository_id = var.repository_id
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_binding" "example" {
  provider = google
  location  = google_artifact_registry_repository.example.location
  repository = google_artifact_registry_repository.example.name
  role        = var.role
  members     = [var.member]
}