provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_secretmanager_secret" "example" {
  secret_id = var.secret_id
  labels = {
    environment = "example"
    application = "secret-manager"
  }
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
  sensitive   = true
}

variable "secret_id" {
  type        = string
  sensitive   = true
}

variable "secret_data" {
  type        = string
  sensitive   = true
}

variable "role" {
  type        = string
  sensitive   = true
}

variable "members" {
  type        = list(string)
  sensitive   = true
}

output "secret_id" {
  value       = google_secretmanager_secret.example.secret_id
  description = "The ID of the secret"
}

output "secret_version_id" {
  value       = google_secretmanager_secret_version.example.id
  description = "The ID of the secret version"
}

output "secret_iam_binding_role" {
  value       = google_secretmanager_secret_iam_binding.example.role
  description = "The role of the secret IAM binding"
}

output "secret_iam_binding_members" {
  value       = google_secretmanager_secret_iam_binding.example.members
  description = "The members of the secret IAM binding"
}