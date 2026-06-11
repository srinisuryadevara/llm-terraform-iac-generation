variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "secret_id" {
  type        = string
  description = "The ID of the secret"
}

variable "secret_name" {
  type        = string
  description = "The name of the secret"
}

variable "member" {
  type        = string
  description = "The member to bind to the secret"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_secret_manager_secret" "secret" {
  secret_id = var.secret_id

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "version" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = "secret-data"
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = google_secret_manager_secret.secret.id
  role       = "roles/secretmanager.secretAccessor"
  member     = var.member
}

resource "google_secret_manager_secret_iam_member" "secret_version_manager" {
  secret_id = google_secret_manager_secret.secret.id
  role       = "roles/secretmanager.secretVersionManager"
  member     = var.member
}

output "secret_id" {
  value = google_secret_manager_secret.secret.id
}

output "secret_version_id" {
  value = google_secret_manager_secret_version.version.id
}