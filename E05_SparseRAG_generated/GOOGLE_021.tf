variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "secret_id" {
  type        = string
  description = "The ID of the secret"
}

variable "secret_accessor_member" {
  type        = string
  description = "The member to be granted secret accessor role"
}

variable "secret_version_manager_member" {
  type        = string
  description = "The member to be granted secret version manager role"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_secret_manager_secret" "example" {
  secret_id = var.secret_id

  replication {
    auto = true
  }
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = google_secret_manager_secret.example.secret_id
  role       = "roles/secretmanager.secretAccessor"
  member     = var.secret_accessor_member
}

resource "google_secret_manager_secret_iam_member" "secret_version_manager" {
  secret_id = google_secret_manager_secret.example.secret_id
  role       = "roles/secretmanager.secretVersionManager"
  member     = var.secret_version_manager_member
}