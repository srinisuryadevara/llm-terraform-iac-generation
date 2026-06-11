terraform {
  required_version = ">= 0.14.0"
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

variable "member" {
  type        = string
  description = "The member to bind to the secret"
}

variable "role" {
  type        = string
  description = "The role to bind to the secret"
}

provider "google" {
  project = var.project
  region  = "us-central1"
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