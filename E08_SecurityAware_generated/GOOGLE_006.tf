variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "service_account_email" {
  type        = string
  description = "Service account email"
}

variable "environment" {
  type        = string
  description = "Environment (e.g., dev, prod)"
}

variable "owner" {
  type        = string
  description = "Owner of the resources"
}

resource "google_project_iam_binding" "service_account_token_creator" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]

  depends_on = [
    google_service_account.service_account,
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    environment = var.environment
    owner       = var.owner
  }
}

resource "google_project_iam_binding" "service_account_user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]

  depends_on = [
    google_service_account.service_account,
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    environment = var.environment
    owner       = var.owner
  }
}

resource "google_service_account" "service_account" {
  account_id = "minimal-service-account"
  project    = var.project

  depends_on = [
    google_project_iam_binding.service_account_token_creator,
    google_project_iam_binding.service_account_user,
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    environment = var.environment
    owner       = var.owner
  }
}