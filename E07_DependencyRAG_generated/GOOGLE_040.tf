variable "project" {
  type        = string
  description = "The ID of the project to create the service account in"
}

variable "service_account_id" {
  type        = string
  description = "The ID of the service account to create"
}

variable "iam_roles" {
  type        = list(string)
  description = "The list of IAM roles to bind to the service account"
}

provider "google" {
  project = var.project
}

resource "google_service_account" "example" {
  account_id   = var.service_account_id
  display_name = "Example Service Account"
}

resource "google_project_iam_binding" "example" {
  count = length(var.iam_roles)

  project = google_service_account.example.project
  role    = var.iam_roles[count.index]
  members = ["serviceAccount:${google_service_account.example.email}"]
}