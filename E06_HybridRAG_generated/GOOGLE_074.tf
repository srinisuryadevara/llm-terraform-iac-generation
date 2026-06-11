terraform {
  required_providers {
    google = {
      version = ">= 3.45.0"
    }
  }
}

variable "project_id" {}
variable "location" {}
variable "repository_id" {}
variable "role" {}
variable "members" {
  type = list(string)
}

provider "google" {
  project = var.project_id
  region  = var.location
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
  repository    = var.repository_id
  role          = var.role
  members       = var.members
}