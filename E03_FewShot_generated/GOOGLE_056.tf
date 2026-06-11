provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloud_function" {
  account_id = var.service_account_id
}

resource "google_service_account_key" "cloud_function" {
  service_account_id = google_service_account.cloud_function.id
}

resource "google_cloudfunctions_function" "http_trigger" {
  name        = var.function_name
  runtime     = var.runtime
  region      = var.region
  entry_point = var.entry_point

  available_memory_mb   = var.available_memory_mb
  timeout               = var.timeout
  service_account_email = google_service_account.cloud_function.email
  trigger {
    http_trigger {
      security_level = "SECURE_OPTIONAL"
    }
  }
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  cloud_function = google_cloudfunctions_function.http_trigger.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "service_account_id" {
  type        = string
  sensitive   = true
}

variable "function_name" {
  type        = string
  sensitive   = true
}

variable "runtime" {
  type        = string
  default     = "nodejs16"
}

variable "entry_point" {
  type        = string
  default     = "helloWorld"
}

variable "available_memory_mb" {
  type        = number
  default     = 128
}

variable "timeout" {
  type        = number
  default     = 60
}