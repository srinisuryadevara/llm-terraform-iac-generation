provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "example" {
  provider = google
  location = var.location
  repository_id = var.repository_id
  format = var.format
}

resource "google_project_iam_binding" "example" {
  project = var.project_id
  role    = var.role

  members = [
    "serviceAccount:${var.service_account}",
  ]
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