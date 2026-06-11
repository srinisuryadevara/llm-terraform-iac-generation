terraform {
  required_version = ">= 0.12.8"
}

variable "project" {
  type = string
}

variable "secret_id" {
  type = string
}

variable "secret_value" {
  type      = string
  sensitive = true
}

variable "role" {
  type = string
}

variable "member" {
  type = string
}

provider "google" {
  version = "~> 4.0"
  project = var.project
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