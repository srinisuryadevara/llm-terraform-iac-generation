terraform {
  required_version = ">= 0.12.8"
}

variable "project" {}
variable "region" {
  default = "us-central1"
}
variable "function_name" {}
variable "function_runtime" {
  default = "nodejs14"
}
variable "function_handler" {
  default = "index.handler"
}
variable "service_account_email" {}

provider "google" {
  version = "~> 2.9.0"
  project = var.project
  region  = var.region
}

provider "google-beta" {
  version = "~> 2.9.0"
  project = var.project
  region  = var.region
}

resource "google_service_account" "cloud_function" {
  account_id = var.function_name
}

resource "google_cloudfunctions_function" "http_function" {
  name        = var.function_name
  runtime     = var.function_runtime
  handler     = var.function_handler
  service_account_email = google_service_account.cloud_function.email
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.http_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

resource "google_cloudfunctions_function_iam_binding" "service_account" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.http_function.name
  role           = "roles/cloudfunctions.serviceAgent"
  members        = ["serviceAccount:${google_service_account.cloud_function.email}"]
}

resource "google_iam_policy" "cloud_function_policy" {
  name        = var.function_name
  description = "Policy for cloud function"

  policy_data = jsonencode({
    "version" : "2012-10-17",
    "statement" : [
      {
        "sid" : "AllowCloudFunctionExecution",
        "effect" : "Allow",
        "action" : [
          "cloudfunctions.cloudPlatform",
          "cloudfunctions.execute",
        ],
        "resource" : "*",
      },
    ]
  })
}

resource "google_iam_role" "cloud_function_role" {
  name        = var.function_name
  description = "Role for cloud function"

  permissions = [
    "cloudfunctions.cloudPlatform",
    "cloudfunctions.execute",
  ]
}

resource "google_iam_role_assignment" "cloud_function_assignment" {
  role       = google_iam_role.cloud_function_role.id
  members    = ["serviceAccount:${google_service_account.cloud_function.email}"]
  condition {
    title       = "Restrict to specific function"
    description = "Only allow execution of specific cloud function"
    expression  = "resource.name.startsWith('projects/${var.project}/locations/${var.region}/functions/${var.function_name}')"
  }
}