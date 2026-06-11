variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account"
}

variable "roles" {
  type        = list(string)
  description = "The list of roles to bind to the service account"
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer"
  ]
}

resource "google_project_iam_binding" "service_account_bindings" {
  project = var.project_id
  role    = var.roles[0]
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

resource "google_project_iam_binding" "service_account_bindings_additional" {
  count  = length(var.roles) > 1 ? length(var.roles) - 1 : 0
  project = var.project_id
  role    = var.roles[count.index + 1]
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}