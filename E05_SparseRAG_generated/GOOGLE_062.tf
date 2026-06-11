variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "prefix" {
  type        = string
  description = "The prefix for the service account"
}

variable "region" {
  type        = string
  description = "The region for the GCP resources"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "minimal_service_account" {
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
  member  = "serviceAccount:${google_service_account.minimal_service_account.email}"
}

resource "google_service_account_key" "minimal_service_account_key" {
  service_account_id = google_service_account.minimal_service_account.id
  public_key_type    = "TYPE_X509_PEM_FILE"
}