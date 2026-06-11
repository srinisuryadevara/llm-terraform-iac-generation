terraform {
  required_version = ">= 0.12.8"
}

# ---------------------------------------------------------------------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "project" {
  type        = string
  description = "The ID of the project to deploy the function to"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region to deploy the function to"
}

variable "function_name" {
  type        = string
  description = "The name of the Cloud Function"
}

variable "function_runtime" {
  type        = string
  default     = "nodejs14"
  description = "The runtime environment of the Cloud Function"
}

variable "function_handler" {
  type        = string
  default     = "index.handler"
  description = "The handler of the Cloud Function"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account to use for the Cloud Function"
}

# ---------------------------------------------------------------------------------------------------------------------
# PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  version = "~> 3.52.0"
  project = var.project
  region  = var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# SERVICE ACCOUNT
# ---------------------------------------------------------------------------------------------------------------------

resource "google_service_account" "function_service_account" {
  account_id = "function-service-account"
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUD FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  runtime     = var.function_runtime
  handler     = var.function_handler
  service_account_email = var.service_account_email
  available_memory_mb   = 128
  timeout_seconds       = 60
  entry_point           = "index.handler"
  https_trigger {
    security_level = "SECURE_ALWAYS"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM POLICIES
# ---------------------------------------------------------------------------------------------------------------------

resource "google_cloudfunctions_service_account_iam_policy" "policy" {
  service_account_id = google_service_account.function_service_account.id
  policy            = data.google_iam_policy.function_policy.policy_data
}

data "google_iam_policy" "function_policy" {
  binding {
    role = "roles/cloudfunctions.invoker"
    members = [
      "allUsers",
    ]
  }
}