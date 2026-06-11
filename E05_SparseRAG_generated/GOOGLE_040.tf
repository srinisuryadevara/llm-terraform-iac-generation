resource "google_service_account" "minimal_account" {
  account_id   = var.service_account_id
  display_name = var.service_account_id
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

variable "project_id" {
  type        = string
  description = "The ID of the project to create the service account in"
}

variable "service_account_id" {
  type        = string
  description = "The ID of the service account to create"
}