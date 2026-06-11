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
  members    = var.secret_access_members
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}

variable "secret_id" {
  type        = string
  description = "The ID of the secret"
}

variable "secret_data" {
  type        = string
  description = "The data of the secret"
  sensitive   = true
}

variable "environment" {
  type        = string
  description = "The environment of the secret"
}

variable "secret_access_members" {
  type        = list(string)
  description = "The members that have access to the secret"
}