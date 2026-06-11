# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a service account! 
resource "google_service_account" "example" {
  account_id = var.service_account_id
  labels = {
    environment = "dev"
    application = "example"
  }
}

# Create a service account IAM binding for the serviceAccountUser role
resource "google_service_account_iam_binding" "example" {
  service_account_id = google_service_account.example.id
  role               = "roles/iam.serviceAccountUser"
  members            = [
    "user:${var.user_email}",
  ]
}

# Create a service account IAM binding for the serviceAccountTokenCreator role
resource "google_service_account_iam_binding" "example2" {
  service_account_id = google_service_account.example.id
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = [
    "user:${var.user_email}",
  ]
}

# Create a service account key for the service account
resource "google_service_account_key" "example" {
  service_account_id = google_service_account.example.id
  public_key_type    = "TYPE_X509_PEM_FILE"
  labels = {
    environment = "dev"
    application = "example"
  }
}

# Declare input variables
variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "service_account_id" {
  type        = string
  sensitive   = true
}

variable "user_email" {
  type        = string
  sensitive   = true
}

# Output key resource attributes
output "service_account_id" {
  value       = google_service_account.example.id
  description = "The ID of the service account"
}

output "service_account_email" {
  value       = google_service_account.example.email
  description = "The email address of the service account"
}

output "service_account_key" {
  value       = google_service_account_key.example.private_key
  sensitive   = true
  description = "The private key of the service account"
}