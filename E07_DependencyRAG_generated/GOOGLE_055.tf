provider "google" {
  version = "~> 4.0"
  project = var.project
  region  = var.region
}

variable "project" {}
variable "region" {}
variable "secret_id" {}
variable "secret_value" {}

resource "google_secretmanager_secret" "example" {
  secret_id = var.secret_id
}

resource "google_secretmanager_secret_version" "example" {
  secret      = google_secretmanager_secret.example.id
  secret_data = var.secret_value
}

resource "google_secretmanager_secret_iam_binding" "example" {
  secret_id = google_secretmanager_secret.example.id
  role       = "roles/secretmanager.secretAccessor"
  members    = [var.member]
}

variable "member" {}