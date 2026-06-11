variable "project_id" {
  type        = string
  description = "The ID of the project to create the service account in"
}

variable "prefix" {
  type        = string
  description = "The prefix to use for the service account name"
}

variable "region" {
  type        = string
  description = "The region to use for the service account"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "minimal_account" {
  account_id   = "${var.prefix}-minimal"
  display_name = "${var.prefix}-minimal"
  description  = "Service account with minimal required roles"
}

resource "google_project_iam_member" "minimal_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.minimal_account.email}"
}