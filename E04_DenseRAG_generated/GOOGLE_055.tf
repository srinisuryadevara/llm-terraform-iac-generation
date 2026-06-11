terraform {
  required_version = ">= 0.12.8"
}

variable "project" {
  type        = string
  description = "The ID of the project to create the secret in"
}

variable "secret_id" {
  type        = string
  description = "The ID of the secret to create"
}

variable "secret_value" {
  type        = string
  sensitive   = true
  description = "The value of the secret to create"
}

variable "role" {
  type        = string
  description = "The role to bind to the secret"
}

variable "members" {
  type        = list(string)
  description = "The members to bind to the secret"
}

provider "google" {
  version = "~> 4.0"
  project = var.project
}

resource "google_secretmanager_secret" "secret" {
  secret_id = var.secret_id
}

resource "google_secretmanager_secret_version" "secret_version" {
  secret      = google_secretmanager_secret.secret.id
  secret_data = var.secret_value
}

resource "google_secretmanager_secret_iam_binding" "secret_iam_binding" {
  secret_id = google_secretmanager_secret.secret.id
  role       = var.role
  members    = var.members
}