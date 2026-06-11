provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_secretmanager_secret" "example" {
  secret_id = var.secret_id
}

resource "google_secretmanager_secret_version" "example" {
  secret      = google_secretmanager_secret.example.id
  secret_data = var.secret_data
}

resource "google_secretmanager_secret_iam_binding" "example" {
  secret_id = google_secretmanager_secret.example.id
  role       = var.role
  members    = var.members
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
}

variable "secret_id" {
  type        = string
}

variable "secret_data" {
  type        = string
  sensitive   = true
}

variable "role" {
  type        = string
}

variable "members" {
  type        = list(string)
}