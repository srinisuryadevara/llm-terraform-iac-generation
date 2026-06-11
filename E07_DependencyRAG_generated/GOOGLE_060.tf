# Configure the Google Cloud Provider
provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

# Create a secret
resource "google_secretmanager_secret" "example" {
  secret_id = var.secret_id
}

# Create a secret version
resource "google_secretmanager_secret_version" "example" {
  secret      = google_secretmanager_secret.example.id
  secret_data = var.secret_data
}

# Create a service account
resource "google_service_account" "example" {
  account_id = var.service_account_id
}

# Create a IAM binding for the service account
resource "google_secretmanager_secret_iam_binding" "example" {
  secret_id = google_secretmanager_secret.example.id
  role       = var.role
  members    = [google_service_account.example.email]
}

# Variables
variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the secret"
}

variable "secret_id" {
  type        = string
  description = "The ID of the secret"
}

variable "secret_data" {
  type        = string
  description = "The data of the secret"
  sensitive   = true
}

variable "service_account_id" {
  type        = string
  description = "The ID of the service account"
}

variable "role" {
  type        = string
  description = "The role of the IAM binding"
}