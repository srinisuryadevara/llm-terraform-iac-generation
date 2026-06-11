variable "project" {
  type        = string
  description = "The ID of the project to create the service account in"
}

variable "service_account_name" {
  type        = string
  description = "The name of the service account to create"
}

variable "iam_roles" {
  type        = list(string)
  description = "The list of IAM roles to bind to the service account"
}

provider "google" {
  project = var.project
}

resource "google_service_account" "example" {
  account_id   = var.service_account_name
  display_name = var.service_account_name
}

resource "google_project_iam_binding" "example" {
  count = length(var.iam_roles)

  project = google_service_account.example.project
  role    = var.iam_roles[count.index]
  members = ["serviceAccount:${google_service_account.example.email}"]
}