variable "project" {
  type        = string
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

variable "secret_value" {
  type        = string
  sensitive   = true
  description = "Secret Value"
}

variable "role" {
  type        = string
  description = "IAM Role"
}

variable "members" {
  type        = list(string)
  description = "List of IAM members"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_secretmanager_secret" "example" {
  secret_id = var.secret_id

  replication {
    automatic = true
  }

  labels = {
    environment = "example"
  }
}

resource "google_secretmanager_secret_version" "example" {
  secret      = google_secretmanager_secret.example.id
  secret_data = var.secret_value
}

resource "google_secretmanager_secret_iam_binding" "example" {
  secret_id = google_secretmanager_secret.example.id
  role       = var.role
  members    = var.members
}