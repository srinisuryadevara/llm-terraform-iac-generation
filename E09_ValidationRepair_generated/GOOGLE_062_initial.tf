provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "example" {
  account_id = var.service_account_id
}

resource "google_service_account_iam_binding" "example" {
  service_account_id = google_service_account.example.id
  role               = "roles/iam.serviceAccountUser"
  members            = [
    "user:${var.user_email}",
  ]
}

resource "google_service_account_iam_binding" "example2" {
  service_account_id = google_service_account.example.id
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = [
    "user:${var.user_email}",
  ]
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "service_account_id" {
  type        = string
  sensitive   = true
}

variable "user_email" {
  type        = string
  sensitive   = true
}