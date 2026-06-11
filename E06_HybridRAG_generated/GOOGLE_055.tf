# This configuration creates a secret in GCP Secret Manager
# and it creates an IAM binding for the secret

# VARIABLES
variable "project" {}
variable "secret_id" {}
variable "secret_value" {}
variable "role" {}
variable "member" {}

# PROVIDERS
provider "google" {
  version = "~> 4.0"
  project = var.project
}

# RESOURCES
resource "google_secretmanager_secret" "secret" {
  secret_id = var.secret_id
}

resource "google_secretmanager_secret_version" "secret_version" {
  secret      = google_secretmanager_secret.secret.id
  secret_data = var.secret_value
}

resource "google_secretmanager_secret_iam_binding" "secret_iam_binding" {
  secret_id = google_secretmanager_secret.secret.id
  role       = var.role
  members    = [var.member]
}