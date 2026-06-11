variable "project_id" {
  type        = string
  sensitive   = true
}

variable "secret_id" {
  type        = string
}

variable "secret_value" {
  type        = string
  sensitive   = true
}

variable "member" {
  type        = string
}

variable "role" {
  type        = string
}

provider "google" {
  project = var.project_id
}

resource "google_secretmanager_secret" "example" {
  secret_id = var.secret_id
}

resource "google_secretmanager_secret_version" "example" {
  secret      = google_secretmanager_secret.example.id
  secret_data = var.secret_value
}

resource "google_secretmanager_secret_iam_binding" "example" {
  secret_id = google_secretmanager_secret.example.id
  role       = var.role
  members    = [var.member]
}