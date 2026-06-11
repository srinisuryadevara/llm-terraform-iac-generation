provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "service_account_email" {
  type        = string
  sensitive   = true
}

variable "roles" {
  type        = list(string)
  default     = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer"
  ]
  sensitive   = true
}

resource "google_project_iam_binding" "service_account" {
  project = var.project_id
  role    = var.roles[0]

  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

resource "google_project_iam_binding" "service_account_monitoring" {
  project = var.project_id
  role    = var.roles[1]

  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

resource "google_project_iam_binding" "service_account_stackdriver" {
  project = var.project_id
  role    = var.roles[2]

  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}