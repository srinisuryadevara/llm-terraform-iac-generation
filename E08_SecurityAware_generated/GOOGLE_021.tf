provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_secretmanager_secret" "example" {
  secret_id = var.secret_id
  replication {
    automatic = true
  }
  labels = {
    environment = var.environment
  }
}

resource "google_secretmanager_secret_version" "example" {
  secret      = google_secretmanager_secret.example.id
  secret_data = var.secret_data
}

resource "google_secretmanager_secret_iam_binding" "example" {
  secret_id = google_secretmanager_secret.example.id
  role       = "roles/secretmanager.secretAccessor"
  members    = ["serviceAccount:${var.service_account_email}"]
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "secret_id" {
  type        = string
  description = "Secret ID"
}

variable "secret_data" {
  type        = string
  sensitive   = true
  description = "Secret Data"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "service_account_email" {
  type        = string
  sensitive   = true
  description = "Service Account Email"
}