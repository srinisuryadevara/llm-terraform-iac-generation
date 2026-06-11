variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "prefix" {
  type        = string
  description = "Prefix for service account"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "service_account_roles" {
  type        = list(string)
  default     = [
    "roles/compute.admin",
    "roles/iam.serviceAccountUser",
    "roles/pubsub.admin",
    "roles/logging.admin",
    "roles/storage.admin"
  ]
  description = "List of roles for service account"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "minimal_account" {
  account_id   = "${var.prefix}-minimal"
  display_name = "${var.prefix}-minimal"
  description  = "Service account with minimal required roles"
}

resource "google_project_iam_member" "minimal_roles" {
  for_each = toset(var.service_account_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.minimal_account.email}"
}

resource "google_service_account_key" "minimal_account_key" {
  service_account_id = google_service_account.minimal_account.id
  public_key_type    = "TYPE_X509_PEM_FILE"
}